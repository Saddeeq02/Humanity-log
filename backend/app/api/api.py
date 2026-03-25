from fastapi import APIRouter
from app.api.endpoints import auth, sync, assignments, dashboard, users, inventory, audits

api_router = APIRouter()
api_router.include_router(auth.router, prefix="/auth", tags=["authentication"])
api_router.include_router(sync.router, prefix="/sync", tags=["sync"])
api_router.include_router(assignments.router, prefix="/assignments", tags=["assignments"])
api_router.include_router(dashboard.router, prefix="/dashboard", tags=["dashboard"])
api_router.include_router(users.router, prefix="/users", tags=["users"])
api_router.include_router(inventory.router, prefix="/inventory", tags=["inventory"])
api_router.include_router(audits.router, prefix="/audits", tags=["audits"])
