from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.orm import selectinload
from typing import List, Optional
import uuid

from app.db.session import get_db
from app.models.assignment import Assignment, AssignmentInventory
from app.models.inventory import InventoryItem

router = APIRouter()

class AssignmentItemSchema(BaseModel):
    inventory_id: str
    quantity: int

class AssignmentCreateSchema(BaseModel):
    user_id: str
    status: str
    geo_fence_polygon: str
    address: str
    latitude: float
    longitude: float
    duration_days: int
    radius_km: float
    allocated_items: List[AssignmentItemSchema]

@router.get("/active")
async def get_active_assignments(db: AsyncSession = Depends(get_db)):
    """
    Returns a list of all currently active or pending assignments map-polygons.
    """
    result = await db.execute(select(Assignment).where(Assignment.status.in_(["pending", "in_progress"])))
    assignments = result.scalars().all()
    
    return {
        "status": "success",
        "data": [
            {
                "id": str(a.id),
                "user_id": str(a.user_id),
                "status": a.status,
                "geo_fence_polygon": a.geo_fence_polygon
            } for a in assignments
        ]
    }

@router.get("/all")
async def get_all_assignments(db: AsyncSession = Depends(get_db)):
    """
    Returns all assignments for the data table.
    """
    # use selectinload to fetch the child inventory mappings instantly
    query = select(Assignment).options(selectinload(Assignment.inventory_allocations).selectinload(AssignmentInventory.inventory_item)).order_by(Assignment.created_at.desc())
    result = await db.execute(query)
    assignments = result.scalars().all()
    
    formatted_data = []
    for a in assignments:
        # Build a text summary of the items (e.g., "500x Rations, 20x Med Kits")
        items_summary = ", ".join([f"{ai.quantity}x {ai.inventory_item.name}" for ai in a.inventory_allocations if ai.inventory_item])
        if not items_summary:
            items_summary = "No items allocated"
            
        formatted_data.append({
            "id": str(a.id),
            "user_id": str(a.user_id),
            "status": a.status,
            "geo_fence_polygon": a.geo_fence_polygon,
            "address": a.address,
            "radius_km": a.radius_km,
            "created_at": a.created_at.isoformat(),
            "allocated_items_summary": items_summary
        })
    
    return {
        "status": "success",
        "data": formatted_data
    }

@router.post("/")
async def create_assignment(data: AssignmentCreateSchema, db: AsyncSession = Depends(get_db)):
    """
    Creates a new mission assignment for a Field Agent.
    """
    try:
        new_assignment = Assignment(
            id=str(uuid.uuid4()),
            user_id=data.user_id,
            status=data.status,
            geo_fence_polygon=data.geo_fence_polygon,
            address=data.address,
            latitude=data.latitude,
            longitude=data.longitude,
            duration_days=data.duration_days,
            radius_km=data.radius_km
        )
        db.add(new_assignment)
        await db.flush() # So we can use the ID instantly
        
        # 2. Attach Inventory Mappings
        for item in data.allocated_items:
            alloc = AssignmentInventory(
                id=str(uuid.uuid4()),
                assignment_id=new_assignment.id,
                inventory_id=item.inventory_id,
                quantity=item.quantity
            )
            db.add(alloc)

        await db.commit()
        await db.refresh(new_assignment)
        
        return {
            "status": "success",
            "data": {
                "id": str(new_assignment.id),
                "status": new_assignment.status
            }
        }
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/user/{user_id}")
async def get_user_assignment(user_id: str, db: AsyncSession = Depends(get_db)):
    """
    Returns the latest assignment for a specific Field Agent.
    Used by the mobile app for Daily Reports and inventory tracking.
    """
    query = select(Assignment).where(
        Assignment.user_id == user_id
    ).options(
        selectinload(Assignment.inventory_allocations).selectinload(AssignmentInventory.inventory_item)
    ).order_by(Assignment.created_at.desc())
    
    result = await db.execute(query)
    assignment = result.scalars().first()
    
    if not assignment:
        return {"status": "success", "data": None}
        
    # Sum up all quantities for the simple daily report view
    total_quantity = sum([item.quantity for item in assignment.inventory_allocations])
    
    return {
        "status": "success",
        "data": {
            "id": str(assignment.id),
            "status": assignment.status,
            "total_assigned_items": total_quantity,
            "items": [
                {
                    "inventory_id": item.inventory_id,
                    "name": item.inventory_item.name if item.inventory_item else "Unknown",
                    "quantity": item.quantity
                } for item in assignment.inventory_allocations
            ]
        }
    }

@router.put("/{id}")
async def update_assignment(id: str, data: AssignmentCreateSchema, db: AsyncSession = Depends(get_db)):
    """
    Updates an existing assignment.
    """
    assignment = await db.get(Assignment, id)
    if not assignment:
        raise HTTPException(status_code=404, detail="Assignment not found")
        
    assignment.user_id = data.user_id
    assignment.status = data.status
    assignment.address = data.address
    assignment.latitude = data.latitude
    assignment.longitude = data.longitude
    assignment.duration_days = data.duration_days
    assignment.radius_km = data.radius_km
    
    # Update allocations (simplified: clear and recreate)
    # 1. Delete old allocations
    from sqlalchemy import delete
    await db.execute(delete(AssignmentInventory).where(AssignmentInventory.assignment_id == id))
    
    # 2. Add new ones
    for item in data.allocated_items:
        alloc = AssignmentInventory(
            id=str(uuid.uuid4()),
            assignment_id=id,
            inventory_id=item.inventory_id,
            quantity=item.quantity
        )
        db.add(alloc)

    await db.commit()
    return {"status": "success", "message": "Assignment updated successfully"}

@router.delete("/{id}")
async def delete_assignment(id: str, db: AsyncSession = Depends(get_db)):
    """
    Deletes an assignment and its allocations.
    """
    assignment = await db.get(Assignment, id)
    if not assignment:
        raise HTTPException(status_code=404, detail="Assignment not found")
        
    await db.delete(assignment)
    await db.commit()
    return {"status": "success", "message": "Assignment deleted permanently"}

@router.get("/{id}/report")
async def get_assignment_report(id: str, db: AsyncSession = Depends(get_db)):
    """
    Generates a mission summary report for Admin review.
    Aggregates distributions, beneficiary info, and location flags.
    """
    from app.models.distribution import DistributionLog, DiscrepancyLog
    from app.models.beneficiary import Beneficiary

    assignment = await db.get(Assignment, id)
    if not assignment:
        raise HTTPException(status_code=404, detail="Assignment not found")
        
    # Fetch all distributions for this assignment
    dist_query = select(DistributionLog).options(selectinload(DistributionLog.beneficiary)).where(DistributionLog.assignment_id == id)
    dist_res = await db.execute(dist_query)
    distributions = dist_res.scalars().all()
    
    # Fetch discrepancies (location flags)
    disc_query = select(DiscrepancyLog).where(DiscrepancyLog.assignment_id == id)
    disc_res = await db.execute(disc_query)
    discrepancies = disc_res.scalars().all()
    
    # Inventory Summary
    inv_query = select(AssignmentInventory).options(selectinload(AssignmentInventory.inventory_item)).where(AssignmentInventory.assignment_id == id)
    inv_res = await db.execute(inv_query)
    inv_items = inv_res.scalars().all()
    
    return {
        "status": "success",
        "data": {
            "id": id,
            "agent_id": str(assignment.user_id),
            "status": assignment.status,
            "beneficiary_count": len(distributions),
            "beneficiaries": [
                {
                    "name": d.beneficiary.name,
                    "timestamp": d.timestamp.isoformat(),
                    "location": d.location_coordinate
                } for d in distributions if d.beneficiary
            ],
            "flags": len(discrepancies),
            "inventory": [
                {
                    "name": i.inventory_item.name if i.inventory_item else "Unknown",
                    "assigned": i.quantity,
                    "returned": i.returned_quantity,
                    "distributed": i.quantity - i.returned_quantity
                } for i in inv_items
            ]
        }
    }

@router.post("/{id}/complete")
async def complete_assignment(id: str, db: AsyncSession = Depends(get_db)):
    """
    Marks an assignment as completed and archives it.
    """
    from datetime import datetime
    assignment = await db.get(Assignment, id)
    if not assignment:
        raise HTTPException(status_code=404, detail="Assignment not found")
        
    assignment.status = "completed"
    assignment.closed_at = datetime.utcnow()
    await db.commit()
    
    return {"status": "success", "message": "Mission marked as completed and archived."}

class ReconciliationItem(BaseModel):
    inventory_id: str
    quantity: int

class ReconciliationSchema(BaseModel):
    returns: List[ReconciliationItem]

@router.post("/{id}/reconcile")
async def reconcile_assignment(id: str, data: ReconciliationSchema, db: AsyncSession = Depends(get_db)):
    """
    Submits final inventory returns from the field agent.
    Moves status to 'reconciling' for Admin final sign-off.
    """
    assignment = await db.get(Assignment, id)
    if not assignment:
        raise HTTPException(status_code=404, detail="Assignment not found")
        
    # Update each returned quantity
    for item in data.returns:
        query = select(AssignmentInventory).where(
            AssignmentInventory.assignment_id == id,
            AssignmentInventory.inventory_id == item.inventory_id
        )
        res = await db.execute(query)
        alloc = res.scalars().first()
        if alloc:
            alloc.returned_quantity = item.quantity
            
    assignment.status = "reconciling"
    await db.commit()
    
    return {"status": "success", "message": "Mission reconciliation submitted for review."}
@router.put("/{id}/suspend")
async def suspend_assignment(id: str, db: AsyncSession = Depends(get_db)):
    """
    Toggles assignment between its current status and 'suspended'.
    """
    assignment = await db.get(Assignment, id)
    if not assignment:
        raise HTTPException(status_code=404, detail="Assignment not found")
        
    if assignment.status == "suspended":
        assignment.status = "active" # Re-activate
    else:
        assignment.status = "suspended"
        
    await db.commit()
    await db.refresh(assignment)
    
    return {
        "status": "success", 
        "message": f"Assignment is now {assignment.status}",
        "data": {"status": assignment.status}
    }
