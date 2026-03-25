from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
import datetime
import os

from app.api.api_v1.api import api_router
from app.api.api_v1.endpoints import refraction

from app.core.config import settings
from app.core.logging_config import setup_logging
from app.db.base import init_db
from app.core.ratelimit import limiter
from slowapi.errors import RateLimitExceeded
from slowapi import _rate_limit_exceeded_handler

# Initialize Logging
logger = setup_logging()

# Initialize Database
init_db()

# Initialize App
app = FastAPI(
    title=settings.PROJECT_NAME,
    openapi_url=f"{settings.API_V1_STR}/openapi.json"
)

# Throttling configuration
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# Request Logging Middleware
@app.middleware("http")
async def log_requests(request: Request, call_next):
    logger.info(f"DEBUG: Incoming {request.method} to {request.url.path}")
    response = await call_next(request)
    logger.info(f"DEBUG: Response status: {response.status_code}")
    return response

# CORS Configuration
allowed_origins = settings.ALLOWED_ORIGINS.split(",")
app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Root Routers
app.include_router(api_router, prefix=settings.API_V1_STR)

# V2 Routers
app.include_router(refraction.router_v2, prefix="/api/v2/refraction", tags=["Medical Refraction Test V2 (AI)"])

# Health Check
@app.get("/api/v1/health", tags=["Health"])
async def health_check():
    return {
        "status": "ok", 
        "message": "Server AI Refraksi Mata berjalan normal (Modular Mode).", 
        "timestamp": datetime.datetime.now()
    }

@app.get("/", tags=["Root"])
async def root():
    return {"message": "Selamat datang di API Refraksi Mata. Silakan gunakan /api/v1/health untuk cek status."}
