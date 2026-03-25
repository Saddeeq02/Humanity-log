from sqlalchemy import Column, String, DateTime, ForeignKey
from datetime import datetime
import uuid
from app.models.base import Base

class AuditLog(Base):
    __tablename__ = "audit_logs"
    __table_args__ = {'extend_existing': True}
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    action = Column(String, nullable=False)  # e.g., "USER_AUTHENTICATED", "ASSIGNMENT_CREATED"
    table_name = Column(String, nullable=True) # Optional: Name of target table
    record_id = Column(String, nullable=True)  # Optional: ID of target record
    target_id = Column(String, nullable=True) # Deprecated/Alias for record_id
    timestamp = Column(DateTime, default=datetime.utcnow)
