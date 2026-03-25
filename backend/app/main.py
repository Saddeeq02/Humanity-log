from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.api import api_router

app = FastAPI(title="SHAS System API", version="1.0.0")

from app.db.session import engine
from sqlalchemy import text

@app.on_event("startup")
async def on_startup():
    # Simple auto-migration for SQLite to add agent_id column
    async with engine.begin() as conn:
        try:
            # Check table info
            result = await conn.execute(text("PRAGMA table_info(users)"))
            columns = [row[1] for row in result.fetchall()]
            
            if 'agent_id' not in columns:
                print("Auto-migration: Adding agent_id column to users table...")
                await conn.execute(text("ALTER TABLE users ADD COLUMN agent_id TEXT"))
                await conn.execute(text("CREATE UNIQUE INDEX IF NOT EXISTS ix_users_agent_id ON users (agent_id)"))
                print("Auto-migration: Successfully added agent_id column.")
        except Exception as e:
            print(f"Auto-migration failed: {e}")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router, prefix="/api/v1")

@app.get("/health")
async def health_check():
    return {"status": "ok", "message": "SHAS FastAPI running reliably!"}

# We will include routers here later
