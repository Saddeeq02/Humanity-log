import asyncio
import sqlite3
from app.db.session import settings

async def patch_db():
    print(f"Connecting to {settings.database_url}...")
    # Since it's SQLite, we can use the standard sqlite3 lib for a simple ALTER TABLE
    db_path = settings.database_url.replace("sqlite+aiosqlite:///", "")
    
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Check if agent_id column exists
        cursor.execute("PRAGMA table_info(users)")
        columns = [column[1] for column in cursor.fetchall()]
        
        if 'agent_id' not in columns:
            print("Adding 'agent_id' column to 'users' table...")
            cursor.execute("ALTER TABLE users ADD COLUMN agent_id TEXT")
            cursor.execute("CREATE UNIQUE INDEX ix_users_agent_id ON users (agent_id)")
            conn.commit()
            print("Successfully patched database.")
        else:
            print("Database already contains 'agent_id' column.")
            
        conn.close()
    except Exception as e:
        print(f"Error patching database: {e}")

if __name__ == "__main__":
    asyncio.run(patch_db())
