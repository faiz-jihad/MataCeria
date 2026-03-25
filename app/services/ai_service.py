import google.generativeai as genai
import os
import logging
from app.core.config import settings
from app.services.research_service import ResearchService

logger = logging.getLogger(__name__)

# Konfigurasi Gemini
if not settings.GEMINI_API_KEY or settings.GEMINI_API_KEY == "YOUR_GEMINI_API_KEY_HERE":
    logger.warning("GEMINI_API_KEY belum dikonfigurasi. Fitur chat AI mungkin tidak berjalan.")
else:
    genai.configure(api_key=settings.GEMINI_API_KEY)

# Konfigurasi Generasi untuk hemat token
generation_config = {
    "temperature": 0.7,
    "top_p": 0.95,
    "top_k": 40,
    "max_output_tokens": 2048, # Diperbesar agar jawaban tidak terpotong
}

# Inisialisasi Model (Primary & Fallbacks)
try:
    # Gemini 2.0 Flash (Latest Stable/Exp for this key)
    model_20 = genai.GenerativeModel(
        model_name='gemini-2.0-flash',
        generation_config=generation_config
    )
    # Gemini 1.5 Flash (Legacy/Stable fallback)
    model_15_flash = genai.GenerativeModel(
        model_name='gemini-1.5-flash',
        generation_config=generation_config
    )
    # Gemini Flash Latest (Alternative fallback)
    model_flash_latest = genai.GenerativeModel(
        model_name='gemini-flash-latest',
        generation_config=generation_config
    )
except Exception as e:
    logger.error(f"Gagal inisialisasi model Gemini: {str(e)}")
    model_20 = None
    model_15_flash = None
    model_flash_latest = None

def get_chat_response(user_query: str, context_articles: list):
    """
    Menghasilkan respon chat menggunakan Gemini dengan RAG.
    Priority: 2.5 Flash -> 2.0 Flash -> 1.5 Flash (Fallback Terakhir)
    """
    if not settings.GEMINI_API_KEY or settings.GEMINI_API_KEY == "YOUR_GEMINI_API_KEY_HERE":
        return "Maaf, sistem AI belum dikonfigurasi. Silakan hubungi admin."

    # 1. Susun context dari 5 artikel terupdate (Hemat Token)
    context_text = ""
    if context_articles:
        context_articles = context_articles[:5] 
        context_text = "Berikut adalah beberapa referensi kesehatan mata internal kami:\n"
        for art in context_articles:
            context_text += f"- {art.title}: {art.content}\n"
    
    # 2. Ambil context riset eksternal (Real-time APIs)
    research_context = ResearchService.get_research_context(user_query)
    
    # 3. Susun Prompt untuk RAG
    prompt = f"""
    Anda adalah asisten AI khusus kesehatan mata (Eye Health Assistant) untuk aplikasi 'Eye Refraksi'.
    
    REFERENSI INTERNAL KAMI:
    {context_text}

    DATA PENELITIAN & MEDIS TERBARU (EKSTERNAL):
    {research_context if research_context else "Tidak ada data riset terbaru untuk topik ini."}

    INSTRUKSI:
    1. PRIORITASKAN referensi internal jika tersedia.
    2. Gunakan DATA PENELITIAN EKSTERNAL jika user bertanya spesifik tentang uji klinis, statistik WHO, izin FDA, atau jurnal terbaru.
    3. Jika tidak ada di referensi keduanya, gunakan pengetahuan medis mata umum.
    4. Gunakan bahasa Indonesia yang santun dan informatif.

    PERTANYAAN PENGGUNA: 
    {user_query}

    JAWABAN ASISTEN AI:
    """

    # COBA 1: Gemini 2.0 Flash (Primary - Latest Available)
    if model_20:
        try:
            logger.info("Mencoba Gemini 2.0 Flash...")
            response = model_20.generate_content(prompt)
            return response.text
        except Exception as e:
            if "finish_reason" in str(e) or "block_reason" in str(e):
                logger.warning(f"Gemini 2.0 blocked partially: {str(e)}")
                return "Maaf, respon terhenti karena kebijakan keamanan AI. Silakan tanyakan hal lain."
            logger.warning(f"Gemini 2.0 gagal: {str(e)}")

    # COBA 2: Gemini 1.5 Flash (Fallback 1)
    if model_15_flash:
        try:
            logger.info("Mencoba Gemini 1.5 Flash...")
            response = model_15_flash.generate_content(prompt)
            return response.text
        except Exception as e:
            if "finish_reason" in str(e) or "block_reason" in str(e):
                logger.warning(f"Gemini 1.5 blocked partially: {str(e)}")
                return "Maaf, respon terhenti karena kebijakan keamanan AI. Silakan tanyakan hal lain."
            logger.warning(f"Gemini 1.5 Flash gagal: {str(e)}")

    # COBA 3: Gemini Flash Latest (Fallback 2)
    if model_flash_latest:
        try:
            logger.info("Mencoba Gemini Flash Latest...")
            response = model_flash_latest.generate_content(prompt)
            return response.text
        except Exception as e:
            # Jika response blocked oleh safety filter, coba ambil yang ada atau beri pesan aman
            if "finish_reason" in str(e) or "block_reason" in str(e):
                logger.warning(f"Gemini Flash blocked partially: {str(e)}")
                return "Maaf, jawaban untuk pertanyaan ini dibatasi oleh kebijakan keamanan AI. Silakan tanyakan hal lain seputar kesehatan mata."
            
            logger.error(f"Semua model Gemini gagal: {str(e)}")
            return "Maaf, saat ini seluruh server AI sedang sangat sibuk. Silakan coba lagi nanti."

    return "Maaf, asisten AI sedang mengalami gangguan teknis sementara."
