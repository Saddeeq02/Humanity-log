from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.orm import joinedload
from app.db.session import get_db
from app.models.audit import AuditLog
from app.models.user import User

router = APIRouter()

@router.get("/all")
async def get_all_audits(db: AsyncSession = Depends(get_db)):
    """
    Returns the global timeline of systemic events.
    """
    query = select(AuditLog, User.name, User.email).join(User, AuditLog.user_id == User.id).order_by(AuditLog.timestamp.desc()).limit(100)
    result = await db.execute(query)
    audits = result.all()
    
    return {
        "status": "success",
        "data": [
            {
                "id": str(log.id),
                "action": log.action,
                "timestamp": log.timestamp.isoformat(),
                "actor_name": name,
                "actor_email": email,
                "target_id": log.target_id
            } for log, name, email in audits
        ]
    }
