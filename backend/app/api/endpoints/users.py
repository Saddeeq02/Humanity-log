from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from passlib.context import CryptContext
import uuid

from app.db.session import get_db
from app.models.user import User

router = APIRouter()
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

class UserCreateSchema(BaseModel):
    name: str
    email: str
    password: str
    role: str

@router.get("/all")
async def get_all_users(db: AsyncSession = Depends(get_db)):
    """
    Returns all registered users for the Super Admin management directory.
    """
    result = await db.execute(select(User).order_by(User.role))
    users = result.scalars().all()
    
    return {
        "status": "success",
        "data": [
            {
                "id": u.id,
                "name": u.name,
                "email": u.email,
                "role": u.role
            } for u in users
        ]
    }

@router.get("/agents")
async def get_agents(db: AsyncSession = Depends(get_db)):
    """
    Returns only Field Agents (For Assignment dropdowns).
    """
    result = await db.execute(select(User).where(User.role == 'agent'))
    agents = result.scalars().all()
    
    return {
        "status": "success",
        "data": [
            {
                "id": a.id,
                "name": a.name,
                "email": a.email
            } for a in agents
        ]
    }

@router.post("/")
async def create_user(data: UserCreateSchema, db: AsyncSession = Depends(get_db)):
    """
    Creates a new sub-admin or field agent with a hashed password.
    """
    # Check if duplicate email
    query = select(User).where(User.email == data.email)
    existing = await db.execute(query)
    if existing.scalars().first():
        raise HTTPException(status_code=400, detail="Email already registered in the system.")
        
    hashed_pwd = pwd_context.hash(data.password)
    
    new_user = User(
        id=str(uuid.uuid4()),
        name=data.name,
        email=data.email,
        role=data.role,
        hashed_password=hashed_pwd
    )
    db.add(new_user)
    await db.commit()
    
    return {"status": "success", "message": f"{data.role} registered securely."}

@router.delete("/{user_id}")
async def delete_user(user_id: str, db: AsyncSession = Depends(get_db)):
    """
    Permanently revokes and deletes a user from the system.
    """
    user = await db.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
        
    if user.role == "superadmin":
        raise HTTPException(status_code=403, detail="The master SuperAdmin account cannot be deleted.")
        
    await db.delete(user)
    await db.commit()
    return {"status": "success", "message": "User permanently removed from the system."}

class PasswordUpdateSchema(BaseModel):
    new_password: str

@router.put("/{user_id}/password")
async def update_user_password(user_id: str, data: PasswordUpdateSchema, db: AsyncSession = Depends(get_db)):
    """
    Overrides and forces a password reset for an Agent.
    """
    user = await db.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
        
    new_hashed = pwd_context.hash(data.new_password)
    user.hashed_password = new_hashed
    await db.commit()
    
    return {"status": "success", "message": "Agent password has been securely overridden."}
