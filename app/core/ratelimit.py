from slowapi import Limiter
from slowapi.util import get_remote_address

# Inisialisasi Limiter dengan default limits
# Key function menggunakan IP Address remote
limiter = Limiter(
    key_func=get_remote_address,
    default_limits=["200/day", "50/hour"]
)
