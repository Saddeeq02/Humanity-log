from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import func
from sqlalchemy.future import select
from typing import Dict, Any

from app.db.session import get_db
from app.models.beneficiary import Beneficiary
from app.models.assignment import Assignment
from app.models.distribution import DistributionLog, DiscrepancyLog
from app.models.audit import AuditLog
from app.models.inventory import InventoryItem

router = APIRouter()

@router.get("/metrics")
async def get_dashboard_metrics(db: AsyncSession = Depends(get_db)):
    """
    Returns aggregated counts for the admin dashboard overview.
    """
    total_beneficiaries = await db.scalar(select(func.count(Beneficiary.id)))
    active_assignments = await db.scalar(
        select(func.count(Assignment.id)).where(Assignment.status.in_(["pending", "in_progress"]))
    )
    total_distributions = await db.scalar(select(func.count(DistributionLog.id)))
    reported_discrepancies = await db.scalar(select(func.count(DiscrepancyLog.id)))
    
    return {
        "status": "success",
        "data": {
            "total_beneficiaries": total_beneficiaries or 0,
            "active_assignments": active_assignments or 0,
            "distributions_today": total_distributions or 0,
            "reported_discrepancies": reported_discrepancies or 0
        }
    }

@router.get("/activity")
async def get_recent_activity(db: AsyncSession = Depends(get_db)):
    """
    Returns the most recent system actions. Right now it just pulls the latest 
    AuditLogs representing synced actions from the field agents.
    """
    # Fetch latest 5 audit logs
    query = select(AuditLog).order_by(AuditLog.timestamp.desc()).limit(5)
    result = await db.execute(query)
    logs = result.scalars().all()
    
    return {
        "status": "success",
        "data": [
            {
                "id": str(log.id),
                "action": log.action,
                "table_name": log.table_name,
                "timestamp": log.timestamp.isoformat()
            } for log in logs
        ]
    }
