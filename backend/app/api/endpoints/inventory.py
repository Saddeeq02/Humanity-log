from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from pydantic import BaseModel
import uuid

from app.db.session import get_db
from app.models.inventory import InventoryItem

router = APIRouter()

@router.get("/all")
async def get_all_inventory(db: AsyncSession = Depends(get_db)):
    """
    Returns the master list of available humanitarian aid items in the warehouses.
    """
    result = await db.execute(select(InventoryItem))
    items = result.scalars().all()
    
    return {
        "status": "success",
        "data": [
            {
                "id": str(i.id),
                "name": i.name,
                "current_stock": i.total_quantity,
                "is_active": i.is_active
            } for i in items
        ]
    }

class InventoryCreateSchema(BaseModel):
    name: str
    total_quantity: int
    
@router.post("/")
async def create_inventory(data: InventoryCreateSchema, db: AsyncSession = Depends(get_db)):
    # Default to HQ for now
    new_item = InventoryItem(
        id=str(uuid.uuid4()),
        organization_id="hq-001",
        name=data.name,
        total_quantity=data.total_quantity,
        is_active=True
    )
    db.add(new_item)
    await db.commit()
    return {"status": "success", "message": "Warehouse aid stored."}

@router.put("/{item_id}/suspend")
async def suspend_inventory(item_id: str, db: AsyncSession = Depends(get_db)):
    item = await db.get(InventoryItem, item_id)
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")
        
    item.is_active = not item.is_active
    await db.commit()
    return {"status": "success", "message": f"Item active state updated to {item.is_active}."}
    
@router.delete("/{item_id}")
async def delete_inventory(item_id: str, db: AsyncSession = Depends(get_db)):
    item = await db.get(InventoryItem, item_id)
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")
        
    await db.delete(item)
    await db.commit()
    return {"status": "success", "message": "Item permanently wiped from Warehouse."}
