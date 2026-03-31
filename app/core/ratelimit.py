from slowapi import Limiter
from slowapi.util import get_remote_address
from app.core.config import settings

# Inisialisasi Limiter dengan default limits dan storage Redis
# Key function menggunakan IP Address remote
limiter = Limiter(
    key_func=get_remote_address,
    storage_uri=settings.REDIS_URL,
    default_limits=["200/day", "50/hour"]
)
