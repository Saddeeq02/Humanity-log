from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
import uuid
import math

from app.db.session import get_db
from app.models.distribution import DistributionLog, Evidence, DiscrepancyLog
from app.models.beneficiary import Beneficiary
from app.models.assignment import Assignment

router = APIRouter()

class BeneficiarySchema(BaseModel):
    id: str
    name: str
    age: int
    location: str
    photo_url: Optional[str] = None
    biometrics: Optional[str] = None

class EvidenceSchema(BaseModel):
    id: str
    photo_url: Optional[str] = None
    gps_verification_status: str

class DistributionLogSchema(BaseModel):
    id: str
    assignment_id: str
    beneficiary_id: str
    agent_id: str # Added agent_id
    timestamp: datetime
    location_coordinate: str
    evidence: Optional[EvidenceSchema] = None

class SyncPushPayload(BaseModel): # Renamed from SyncPushRequest
    agent_id: str
    logs: List[DistributionLogSchema] # Renamed from distributions
    new_beneficiaries: List[BeneficiarySchema]

def calculate_haversine_distance(lat1, lon1, lat2, lon2):
    R = 6371.0 # Earth radius in kilometers
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = math.sin(dlat / 2)**2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon / 2)**2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    distance = R * c
    return distance

@router.post("/push")
async def sync_push(payload: SyncPushPayload, db: AsyncSession = Depends(get_db)):
    """
    Receives an array of offline distribution logs.
    Iterates through them transactionally and catches GPS discrepancies!
    """
    try:
        inserted_logs = 0
        flagged_discrepancies = 0

        # Insert New Beneficiaries
        for ben_data in payload.new_beneficiaries:
            ben = Beneficiary(
                id=ben_data.id,
                name=ben_data.name,
                age=ben_data.age,
                location=ben_data.location,
                photo_url=ben_data.photo_url,
                biometrics=ben_data.biometrics
            )
            db.add(ben)

        # Insert Distribution Logs
        for dist_data in payload.logs:
            log = DistributionLog(
                id=dist_data.id,
                assignment_id=dist_data.assignment_id,
                beneficiary_id=dist_data.beneficiary_id,
                agent_id=dist_data.agent_id,
                timestamp=dist_data.timestamp,
                location_coordinate=dist_data.location_coordinate
            )
            db.add(log)
            
            # --- Smart Check: Geo Fence Fraud against Assigned Coordinates ---
            if dist_data.assignment_id and dist_data.location_coordinate:
                assignment = await db.get(Assignment, dist_data.assignment_id)
                if assignment and assignment.latitude and assignment.longitude:
                    try:
                        agent_lat_str, agent_lng_str = dist_data.location_coordinate.split(',')
                        agent_lat = float(agent_lat_str.strip())
                        agent_lng = float(agent_lng_str.strip())
                        
                        dist_km = calculate_haversine_distance(
                            agent_lat, agent_lng, 
                            assignment.latitude, assignment.longitude
                        )
                        
                        if dist_km > assignment.radius_km:
                            flagged_discrepancies += 1
                            fraud_flag = DiscrepancyLog(
                                id=str(uuid.uuid4()),
                                assignment_id=assignment.id,
                                reported_by=dist_data.agent_id,
                                discrepancy_type="Location Mismatch",
                                expected_value=f"{assignment.latitude},{assignment.longitude} (Radius: {assignment.radius_km}km)",
                                actual_value=dist_data.location_coordinate,
                                resolution_status="pending",
                                notes=f"Agent distributed aid {dist_km:.2f} km outside of the mission zone."
                            )
                            db.add(fraud_flag)
                    except Exception as parse_err:
                        print(f"Geo parse error during sync: {parse_err}")

            if dist_data.evidence:
                ev = Evidence(
                    id=dist_data.evidence.id,
                    distribution_id=dist_data.id,
                    photo_url=dist_data.evidence.photo_url,
                    gps_verification_status=dist_data.evidence.gps_verification_status
                )
                db.add(ev)
            
            inserted_logs += 1

        # Commit bulk sync transaction
        await db.commit()
        return {"status": "success", "synced_records": inserted_logs, "discrepancies_flagged": flagged_discrepancies}
    
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/pull")
async def pull_assignments(agent_id: str, db: AsyncSession = Depends(get_db)):
    """
    Returns latest beneficiary ledgers required for the agent's offline cache.
    """
    # Simply retrieving beneficiaries as an example
    result = await db.execute(select(Beneficiary))
    beneficiaries = result.scalars().all()
    
    return {
        "beneficiaries": [
            {
                "id": str(b.id),
                "name": b.name,
                "location": b.location
            } for b in beneficiaries
        ]
    }
