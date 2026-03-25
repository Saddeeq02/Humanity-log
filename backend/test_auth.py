import asyncio
from httpx import AsyncClient
from app.main import app
async def test():
    async with AsyncClient(app=app, base_url="http://test") as ac:
        response = await ac.post("/api/v1/auth/login", data={"username": "superadmin@humanitylog.org", "password": "Admin@123"})
        print(response.status_code)
        print(response.json())
asyncio.run(test())
