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
