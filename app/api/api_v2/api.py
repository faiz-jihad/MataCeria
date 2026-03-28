from fastapi import APIRouter
from app.api.api_v1.endpoints import refraction, chat

api_router = APIRouter()

# V2 Endpoints
api_router.include_router(refraction.router_v2, prefix="/refraction", tags=["Medical Refraction Test V2 (AI)"])
api_router.include_router(chat.router, prefix="/chat", tags=["AI Chatbot V2"])
