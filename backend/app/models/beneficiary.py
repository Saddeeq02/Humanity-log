from sqlalchemy import Column, String, Integer, Float
import uuid
from app.models.base import Base

class Beneficiary(Base):
    __tablename__ = "beneficiaries"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    name = Column(String, nullable=False)
    age = Column(Integer, nullable=False)
    location = Column(String, nullable=False)
    gps_coordinates = Column(String, nullable=True)
    photo_url = Column(String, nullable=True)
    biometric_hash = Column(String, nullable=True)
    qr_code_id = Column(String, nullable=True)
