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

# Menggunakan model Gemini 2.0 Flash dengan Batasan Token
try:
    # Konfigurasi Generasi untuk hemat token
    generation_config = {
        "temperature": 0.7,
        "top_p": 0.95,
        "top_k": 40,
        "max_output_tokens": 800, # Batasi output agar tidak boros
    }
    model = genai.GenerativeModel(
        model_name='gemini-2.0-flash',
        generation_config=generation_config
    )
except Exception as e:
    logger.error(f"Gagal inisialisasi Gemini 2.0: {str(e)}")
    try:
        model = genai.GenerativeModel('gemini-1.5-flash')
    except:
        model = None

def get_chat_response(user_query: str, context_articles: list):
    """
    Menghasilkan respon chat menggunakan Gemini dengan RAG.
    """
    if not settings.GEMINI_API_KEY or settings.GEMINI_API_KEY == "YOUR_GEMINI_API_KEY_HERE" or model is None:
        return "Maaf, sistem AI belum dikonfigurasi. Silakan hubungi admin."

    try:
        # 1. Susun context dari 5 artikel terupdate saja (Hemat Token)
        context_text = ""
        if context_articles:
            # Ambil maksimal 5 artikel saja untuk menghemat input token
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

        response = model.generate_content(prompt)
        return response.text

    except Exception as e:
        logger.error(f"Error saat memanggil Gemini API: {str(e)}")
        return "Maaf, asisten AI sedang mengalami gangguan teknis."
