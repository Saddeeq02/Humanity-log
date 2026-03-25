import sqlite3
import os

def patch_db(db_path):
    if not os.path.exists(db_path):
        print(f"Database {db_path} not found.")
        return

    print(f"Patching {db_path}...")
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Check if agent_id column exists
        cursor.execute("PRAGMA table_info(users)")
        columns = [column[1] for column in cursor.fetchall()]
        
        if 'agent_id' not in columns:
            print(f"Adding 'agent_id' column to 'users' table in {db_path}...")
            cursor.execute("ALTER TABLE users ADD COLUMN agent_id TEXT")
            cursor.execute("CREATE UNIQUE INDEX IF NOT EXISTS ix_users_agent_id ON users (agent_id)")
            conn.commit()
            print(f"Successfully patched {db_path}.")
        else:
            print(f"Database {db_path} already contains 'agent_id' column.")
            
        conn.close()
    except Exception as e:
        print(f"Error patching {db_path}: {e}")

if __name__ == "__main__":
    patch_db("shas_dev.db")
    patch_db("database.db")
