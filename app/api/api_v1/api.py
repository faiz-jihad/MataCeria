from fastapi import APIRouter
from app.api.api_v1.endpoints import auth, user, testing, articles, chat, emergency, notifications, misc, refraction, admin

# Mengatur redirect_slashes=False tetap di-handle di level FastAPI utama jika perlu, 
# tapi di sini kita definisikan router utama tanpa paksaan slash.
api_router = APIRouter(redirect_slashes=False)

api_router.include_router(auth.router, prefix="/auth", tags=["Authentication"])
api_router.include_router(user.router, prefix="/user", tags=["User Profile"])
api_router.include_router(testing.router, prefix="", tags=["Eye Refraction Test"])
api_router.include_router(refraction.router, prefix="/refraction", tags=["Medical Refraction Test"])
api_router.include_router(articles.router, prefix="/articles", tags=["Articles"])
api_router.include_router(chat.router, prefix="/chat", tags=["AI Chat"])
api_router.include_router(emergency.router, prefix="/emergency/contacts", tags=["Emergency Contacts"])
api_router.include_router(notifications.router, prefix="/notifications", tags=["Notifications"])
api_router.include_router(admin.router, prefix="/admin", tags=["Admin Tools"])
api_router.include_router(misc.router, prefix="", tags=["Miscellaneous"])
