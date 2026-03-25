import asyncio
import uuid
from app.db.session import engine
from app.models.base import Base
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.asyncio import AsyncSession
from passlib.context import CryptContext

from app.models.user import User
from app.models.inventory import InventoryItem

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

async def seed_db():
    Session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    async with Session() as session:
        # Seed Super Admin
        super_pwd = pwd_context.hash("Admin@123")
        super_admin = User(
            id=str(uuid.uuid4()),
            email="superadmin@humanitylog.org",
            name="Global Director",
            role="superadmin",
            hashed_password=super_pwd
        )
        
        # Seed an Agent
        agent_pwd = pwd_context.hash("Agent@123")
        agent_id = str(uuid.uuid4())
        agent = User(
            id=agent_id,
            email="agent007@humanitylog.org",
            name="James Bond",
            role="agent",
            hashed_password=agent_pwd,
            agent_id="AGENT007"
        )
        session.add_all([super_admin, agent])
        
        # Seed Inventory
        inv1 = InventoryItem(
            id=str(uuid.uuid4()),
            organization_id="hq-001",
            name="Emergency Food Rations",
            total_quantity=5000
        )
        inv2 = InventoryItem(
            id=str(uuid.uuid4()),
            organization_id="hq-001",
            name="Medical First-Aid Kits",
            total_quantity=1200
        )
        inv3 = InventoryItem(
            id=str(uuid.uuid4()),
            organization_id="hq-001",
            name="Thermal Blankets",
            total_quantity=3500
        )
        session.add_all([inv1, inv2, inv3])
        
        await session.commit()
    print("Database seeded with Global Director, Agent 007, and Warehouse items.")

if __name__ == "__main__":
    asyncio.run(seed_db())
