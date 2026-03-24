from fastapi import APIRouter

router = APIRouter()

@router.get("/conditions")
async def get_eye_conditions():
    """
    Mengembalikan daftar kondisi mata umum untuk ditampilkan di UI Flutter.
    """
    return [
        {"id": "normal", "name": "Mata Normal", "description": "Penglihatan jernih tanpa bantuan alat."},
        {"id": "miopia", "name": "Miopia (Rabun Jauh)", "description": "Kesulitan melihat objek jauh dengan jelas."},
        {"id": "hipermetropia", "name": "Hipermetropia (Rabun Dekat)", "description": "Kesulitan melihat objek dekat dengan jelas."},
        {"id": "astigmatisme", "name": "Silinder (Astigmatisme)", "description": "Pandangan kabur atau berbayang karena kelengkungan kornea tidak merata."}
    ]

@router.post("/logout")
async def logout():
    """
    Endpoint logout standar. 
    Karena menggunakan JWT stateless, logout biasanya ditangani di sisi klien 
    dengan menghapus token. Di sisi server, kita cukup mengembalikan sukses.
    """
    return {"message": "Berhasil logout. Silakan hapus token Anda di sisi klien."}
