import cv2
import numpy as np
import tensorflow as tf
import os
import logging

from app.core.config import settings

logger = logging.getLogger(__name__)

# Konfigurasi Path Model
# Load model (Lakukan satu kali saja saat startup)
try:
    path = settings.MODEL_PATH
    # Cek model_miopia.h5 atau model_refraksi.h5
    if not os.path.exists(path) and os.path.exists("model_refraksi.h5"):
        path = "model_refraksi.h5"
        
    if os.path.exists(path):
        logger.info(f"Memuat Model AI dari: {path}")
        model = tf.keras.models.load_model(path)
    else:
        logger.error(f"Model AI tidak ditemukan di {path}! Prediksi akan gagal.")
        model = None
except Exception as e:
    logger.error(f"Error saat memuat model: {str(e)}")
    model = None

def predict_refraction(image_path: str):
    """
    Melakukan prediksi hasil refraksi (Miopia) dari gambar.
    Output: hasil_klasifikasi (str), estimasi_dioptri (str), confidence (float)
    """
    if model is None:
        return "Internal Error", "N/A", 0.0

    try:
        # 1. Baca Gambar dengan OpenCV
        img = cv2.imread(image_path)
        if img is None:
            raise Exception("Gambar tidak terbaca")

        # 2. Preprocessing (Resize & Normalisasi)
        # Sesuai input training model (Misal: 224x224 untuk MobileNet)
        img_resized = cv2.resize(img, (224, 224))
        img_array = np.expand_dims(img_resized, axis=0) / 255.0

        # 3. Lakukan Prediksi
        prediction = model.predict(img_array)
        
        # MOCK LOGIC (Sesuaikan dengan arsitektur model final Anda)
        # Index 0: Normal, Index 1: Miopia Ringan, Index 2: Miopia Berat
        classes = ["Normal", "Miopia Ringan", "Miopia Berat"]
        dioptri_ranges = ["0.00", "-0.25 s/d -3.00", "> -3.00"]
        
        idx = np.argmax(prediction)
        confidence = float(np.max(prediction))

        return classes[idx], dioptri_ranges[idx], confidence

    except Exception as e:
        logger.error(f"Gagal memproses AI: {str(e)}")
        raise e
