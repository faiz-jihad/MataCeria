from sqlalchemy.orm import declarative_base
import enum

# Base class untuk semua tabel
Base = declarative_base()

# ==========================================
# DEFINISI ENUM (PILIHAN DROPDOWN)
# ==========================================
class UserRole(str, enum.Enum):
    USER = "user"
    ADMIN = "admin"

class JenisKelamin(str, enum.Enum):
    LAKI_LAKI = "Laki-laki"
    PEREMPUAN = "Perempuan"

class JenjangPendidikan(str, enum.Enum):
    SD = "SD"
    SMP = "SMP"
    SMA = "SMA"
    D3 = "D3"
    D4_S1 = "D4/S1"
    S2_S3 = "S2/S3"
    LAINNYA = "Lainnya"

class StatusPekerjaan(str, enum.Enum):
    PELAJAR_MAHASISWA = "Pelajar/Mahasiswa"
    BEKERJA = "Bekerja"
    TIDAK_BEKERJA = "Tidak Bekerja"
