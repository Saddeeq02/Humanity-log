from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import or_
from passlib.context import CryptContext
import jwt
from datetime import datetime, timedelta

from app.db.session import get_db
from app.models.user import User
from app.models.audit import AuditLog

router = APIRouter()
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
SECRET_KEY = "super-secret-humanitylog-jwt-key"
ALGORITHM = "HS256"

@router.post("/login")
async def login(form_data: OAuth2PasswordRequestForm = Depends(), db: AsyncSession = Depends(get_db)):
    """
    Standard OAuth2 flow: takes username (email or agent_id) and password.
    Returns access token with injected Role for frontend RBAC routing.
    """
    query = select(User).where(
        or_(
            User.email == form_data.username,
            User.agent_id == form_data.username
        )
    )
    result = await db.execute(query)
    user = result.scalars().first()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
        
    # Verify Password
    if not pwd_context.verify(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
        
    # Verification Succeeded
    audit_entry = AuditLog(
        user_id=user.id,
        action="AUTHENTICATED_SESSION",
        table_name="users",
        record_id=user.id
    )
    db.add(audit_entry)
    await db.commit()

    # JWT generation
    access_token_expires = timedelta(minutes=1440) # 24 hrs
    expire = datetime.utcnow() + access_token_expires
    
    encoded_jwt = jwt.encode(
        {"sub": user.email, "role": user.role, "id": user.id, "exp": expire},
        SECRET_KEY, 
        algorithm=ALGORITHM
    )

    return {
        "access_token": encoded_jwt, 
        "token_type": "bearer",
        "user": {
            "id": user.id,
            "email": user.email,
            "name": user.name,
            "role": user.role
        }
    }
