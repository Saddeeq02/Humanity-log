import os
from pydantic import BaseModel

class Settings(BaseModel):
    PROJECT_NAME: str = "SHAS Backend API"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"
    
    POSTGRES_USER: str = os.getenv("POSTGRES_USER", "postgres")
    POSTGRES_PASSWORD: str = os.getenv("POSTGRES_PASSWORD", "postgres")
    POSTGRES_SERVER: str = os.getenv("POSTGRES_SERVER", "localhost")
    POSTGRES_PORT: str = os.getenv("POSTGRES_PORT", "5432")
    POSTGRES_DB: str = os.getenv("POSTGRES_DB", "shas_db")
    
    @property
    def async_database_url(self) -> str:
        return "sqlite+aiosqlite:///./shas_dev.db"

settings = Settings()
