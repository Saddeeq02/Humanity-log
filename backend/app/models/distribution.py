from sqlalchemy import Column, String, Integer, ForeignKey, DateTime
from sqlalchemy.orm import relationship
import uuid
from datetime import datetime
from app.models.base import Base

class DistributionLog(Base):
    __tablename__ = "distribution_logs"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    assignment_id = Column(String, ForeignKey("assignments.id"), nullable=False)
    beneficiary_id = Column(String, ForeignKey("beneficiaries.id"), nullable=False)
    timestamp = Column(DateTime, default=datetime.utcnow)
    location_coordinate = Column(String, nullable=True)

class Evidence(Base):
    __tablename__ = "evidence"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    distribution_log_id = Column(String, ForeignKey("distribution_logs.id"), nullable=False)
    photo_url = Column(String, nullable=True)
    gps_verification_status = Column(String, nullable=True)

class DiscrepancyLog(Base):
    __tablename__ = "discrepancy_logs"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    assignment_id = Column(String, ForeignKey("assignments.id"), nullable=False)
    item_id = Column(String, ForeignKey("inventory_items.id"), nullable=True) # Optional for location mismatches
    
    reported_by = Column(String, ForeignKey("users.id"), nullable=True)
    discrepancy_type = Column(String, nullable=False) # "Stock Mismatch", "Location Mismatch"
    
    expected_value = Column(String, nullable=True)
    actual_value = Column(String, nullable=True)
    
    resolution_status = Column(String, default="pending") # "pending", "resolved", "dismissed"
    notes = Column(String, nullable=True)
    timestamp = Column(DateTime, default=datetime.utcnow)
    
