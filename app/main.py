from fastapi import FastAPI, Request, Response
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from app.core.templates import templates
import datetime
import os

from app.api.api_v1.api import api_router as api_v1_router
from app.api.api_v2.api import api_router as api_v2_router
from app.core.config import settings
from app.core.logging_config import setup_logging
from app.db.base import init_db
from app.core.ratelimit import limiter
from slowapi.errors import RateLimitExceeded
from slowapi import _rate_limit_exceeded_handler
from prometheus_fastapi_instrumentator import Instrumentator

# Initialize Logging
logger = setup_logging()

# Initialize Database
init_db()

# Initialize App
app = FastAPI(
    title=settings.PROJECT_NAME,
    openapi_url=f"{settings.API_V1_STR}/openapi.json",
    description="Sistem AI Refraksi Mata"
)

# Initialize Prometheus Instrumentator
Instrumentator().instrument(app).expose(app)

# Throttling configuration
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# --- MIDDLEWARE ---

# Security Headers Middleware
@app.middleware("http")
async def add_security_headers(request: Request, call_next):
    response: Response = await call_next(request)
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["X-XSS-Protection"] = "1; mode=block"
    response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
    return response

# Request Logging Middleware
@app.middleware("http")
async def log_requests(request: Request, call_next):
    logger.info(f"Incoming {request.method} to {request.url.path}")
    response = await call_next(request)
    logger.info(f"Response status: {response.status_code}")
    return response

# CORS Configuration
allowed_origins = settings.ALLOWED_ORIGINS.split(",")

# Jika menggunakan "*" dan allow_credentials=True, FastAPI akan Error.
# Kita tangani dengan mengizinkan semua origin secara dinamis jika "*" disetel.
if "*" in allowed_origins:
    app.add_middleware(
        CORSMiddleware,
        allow_origin_regex=".*", # Mengizinkan semua origin dengan regex agar kompatibel dengan credentials
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
else:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=allowed_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

# --- ROUTERS ---

# V1 Routers
app.include_router(api_v1_router, prefix=settings.API_V1_STR)

# V2 Routers
app.include_router(api_v2_router, prefix="/api/v2")

# Mount Static Files (Uploads)
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

# Health Check
@app.get("/health", tags=["Health"])
async def health_check():
    return {
        "status": "ok", 
        "message": "Server AI Refraksi Mata berjalan normal.", 
        "timestamp": datetime.datetime.now()
    }

@app.get("/", tags=["Root"])
async def root():
    return {
        "status": "ok",
        "message": "Selamat datang di API Refraksi Mata V2 ",
        "docs": "/docs"
    }
