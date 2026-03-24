import google.generativeai as genai
import os
import logging
from app.core.config import settings

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
    "max_output_tokens": 800,
}

# Inisialisasi Model (Primary & Fallbacks)
try:
    model_25 = genai.GenerativeModel(
        model_name='gemini-2.5-flash',
        generation_config=generation_config
    )
    model_20 = genai.GenerativeModel(
        model_name='gemini-2.0-flash',
        generation_config=generation_config
    )
    model_15 = genai.GenerativeModel(
        model_name='gemini-1.5-flash',
        generation_config=generation_config
    )
except Exception as e:
    logger.error(f"Gagal inisialisasi model Gemini: {str(e)}")
    model_25 = None
    model_20 = None
    model_15 = None

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
        context_text = "Berikut adalah beberapa referensi kesehatan mata:\n"
        for art in context_articles:
            context_text += f"- {art.title}: {art.content}\n"
    
    # 2. Susun Prompt untuk RAG
    prompt = f"""
    Anda adalah asisten AI khusus kesehatan mata (Eye Health Assistant) untuk aplikasi 'Eye Refraksi'.
    
    REFERENSI INTERNAL KAMI:
    {context_text}

    INSTRUKSI:
    1. Gunakan referensi di atas untuk menjawab.
    2. Jika tidak ada di referensi, gunakan pengetahuan medis mata umum.
    3. Gunakan bahasa Indonesia yang santun.

    PERTANYAAN PENGGUNA: 
    {user_query}

    JAWABAN ASISTEN AI:
    """

    # COBA 1: Gemini 2.5 Flash (Primary)
    if model_25:
        try:
            logger.info("Mencoba Gemini 2.5 Flash...")
            response = model_25.generate_content(prompt)
            return response.text
        except Exception as e:
            logger.warning(f"Gemini 2.5 gagal: {str(e)}")

    # COBA 2: Gemini 2.0 Flash (Secondary)
    if model_20:
        try:
            logger.info("Mencoba Gemini 2.0 Flash...")
            response = model_20.generate_content(prompt)
            return response.text
        except Exception as e:
            logger.warning(f"Gemini 2.0 gagal: {str(e)}")

    # COBA 3: Gemini 1.5 Flash (Final Fallback - Paling Stabil)
    if model_15:
        try:
            logger.info("Mencoba Gemini 1.5 Flash (Stable Fallback)...")
            response = model_15.generate_content(prompt)
            return response.text
        except Exception as e:
            logger.error(f"Semua model Gemini gagal: {str(e)}")
            return "Maaf, saat ini seluruh server AI sedang sangat sibuk. Silakan coba lagi nanti."

    return "Maaf, asisten AI sedang mengalami gangguan teknis sementara."
