from sqlalchemy import Column, String, DateTime, ForeignKey, Float, Integer
from sqlalchemy.orm import relationship
import uuid
from datetime import datetime
from app.models.base import Base

class Assignment(Base):
    __tablename__ = "assignments"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    status = Column(String, default="pending")
    geo_fence_polygon = Column(String, nullable=True) 
    
    address = Column(String, nullable=True)
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    duration_days = Column(Integer, default=1)
    radius_km = Column(Float, default=1.0) 
    
    inventory_allocations = relationship("AssignmentInventory", back_populates="assignment")

class AssignmentInventory(Base):
    __tablename__ = "assignment_inventory"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    assignment_id = Column(String, ForeignKey("assignments.id"), nullable=False)
    inventory_id = Column(String, ForeignKey("inventory_items.id"), nullable=False)
    quantity = Column(Integer, default=0)
    
    assignment = relationship("Assignment", back_populates="inventory_allocations")
    inventory_item = relationship("InventoryItem")
