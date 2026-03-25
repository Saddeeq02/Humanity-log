import asyncio
from app.db.session import engine
from app.models.base import Base
import app.models.assignment
import app.models.user
import app.models.beneficiary
import app.models.inventory
import app.models.distribution
import app.models.audit

async def init_db():
    async with engine.begin() as conn:
        # Create all tables
        await conn.run_sync(Base.metadata.drop_all)
        await conn.run_sync(Base.metadata.create_all)
    print("Database completely reset and tables recreated!")

if __name__ == "__main__":
    asyncio.run(init_db())
