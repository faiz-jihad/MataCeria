import os
import cv2
import numpy as np
import base64
import logging
from app import schemas
from app.services.refraction_service import RefractionService

# Limit TF logs
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '2'

logger = logging.getLogger(__name__)

# Try importing tensorflow, but fail gracefully if issues occur
try:
    import tensorflow as tf
    TF_AVAILABLE = True
except ImportError:
    TF_AVAILABLE = False
    logger.warning("TensorFlow is not installed. AI Inference will run in dummy mode.")

class AIRefractionService:
    # Model cache
    _model = None
    _model_loaded = False
    
    # Classification map
    CLASS_MAPPING = {
        0: "Normal",
        1: "Mild Impairment",
        2: "Myopia",
        3: "Severe Impairment"
    }

    @classmethod
    def load_model(cls):
        """Load TF/Keras model once into memory."""
        if cls._model_loaded:
            return cls._model
            
        if not TF_AVAILABLE:
            return None

        model_path = os.getenv("AI_MODEL_PATH", "model_miopia.h5")
        try:
            if os.path.exists(model_path):
                cls._model = tf.keras.models.load_model(model_path)
                logger.info(f"Loaded AI model from {model_path}")
            else:
                logger.warning(f"AI Model not found at {model_path}. Inference will be simulated.")
                cls._model = None
        except Exception as e:
            logger.error(f"Error loading AI model: {e}")
            cls._model = None
            
        cls._model_loaded = True
        return cls._model

    @staticmethod
    def decode_and_preprocess_image(base64_string: str) -> np.ndarray:
        """Decode base64 and preprocess image for the model."""
        # 1. Decode base64
        if ',' in base64_string:
            base64_string = base64_string.split(',')[1]
            
        img_data = base64.b64decode(base64_string)
        nparr = np.frombuffer(img_data, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        if img is None:
            raise ValueError("Invalid image data.")

        # 2. Resize -> 224x224
        img_resized = cv2.resize(img, (224, 224))
        
        # 3. Normalize (0-1)
        img_normalized = img_resized.astype("float32") / 255.0
        
        # Add batch dimension
        img_tensor = np.expand_dims(img_normalized, axis=0)
        return img_tensor

    @classmethod
    def get_rule_based_class(cls, decimal_acuity: float) -> int:
        """Map decimal acuity to 0-3 classes."""
        if decimal_acuity >= 1.0:
            return 0  # Normal
        elif 0.5 <= decimal_acuity < 1.0:
            return 1  # Mild
        elif 0.3 <= decimal_acuity < 0.5:
            return 2  # Myopia
        else:
            return 3  # Severe

    @classmethod
    def predict(cls, request_data: schemas.RefractionAIRequest) -> schemas.RefractionAIResultDetail:
        """
        Main pipeline for Hybrid AI Refraction processing.
        """
        # --- 1. PREPROCESSING IMAGE ---
        try:
            image_tensor = cls.decode_and_preprocess_image(request_data.image_data.eye_frame_base64)
        except Exception as e:
            logger.error(f"Image preprocessing failed: {e}")
            raise ValueError("Gagal memproses gambar mata.")

        # --- 2. SNELLEN RULE CALCULATION ---
        # Note: We reuse calculate_acuity from RefractionService
        snellen_fraction, decimal_acuity = RefractionService.calculate_acuity(
            smallest_row=request_data.snellen_data.smallest_row_read,
            missed_chars=request_data.snellen_data.missed_chars
        )
        rule_class = cls.get_rule_based_class(decimal_acuity)

        # --- 3. AI MODEL INFERENCE ---
        model = cls.load_model()
        ai_class = 0
        ai_confidence = 0.0
        source = "rule_based_fallback"
        
        if model is not None:
            try:
                # Output: probability per class e.g. [0.1, 0.7, 0.1, 0.1]
                preds = model.predict(image_tensor, verbose=0)
                probabilities = preds[0]
                ai_class = int(np.argmax(probabilities))
                ai_confidence = float(probabilities[ai_class])
                source = "hybrid_model"
            except Exception as e:
                logger.error(f"Inference error: {e}")
                # Fallback to rule if AI fails during predict
                ai_class = rule_class
                ai_confidence = 1.0
        else:
            # --- GEMINI VISION FALLBACK (Dynamic AI) ---
            from app.core.config import settings
            import google.generativeai as genai
            import PIL.Image
            import io

            try:
                logger.info("Local model missing, falling back to Gemini Vision multimodal...")
                genai.configure(api_key=settings.GEMINI_API_KEY)
                v_model = genai.GenerativeModel('gemini-1.5-flash')
                
                # Convert base64 to PIL
                if ',' in request_data.image_data.eye_frame_base64:
                    b64_data = request_data.image_data.eye_frame_base64.split(',')[1]
                else:
                    b64_data = request_data.image_data.eye_frame_base64
                
                img_pil = PIL.Image.open(io.BytesIO(base64.b64decode(b64_data)))
                
                # Multi-modal prompt
                prompt = f"""
                Analyze this eye image for a refraction screening app. 
                Patient Snellen score is {snellen_fraction} (decimal {decimal_acuity}).
                
                Compare the visual signs (eye strain, redness, clarity) with the Snellen score.
                Classify into one of these integers:
                0: Normal
                1: Mild Impairment
                2: Myopia (Rabun Jauh)
                3: Severe Impairment
                
                Respond in exactly this JSON format:
                {{"class": integer, "confidence": float, "analysis": "brief reasoning"}}
                """
                
                response = v_model.generate_content([prompt, img_pil])
                import json
                # Extract JSON from response.text (handle potential markdown blocks)
                res_text = response.text.strip().replace('```json', '').replace('```', '')
                res_json = json.loads(res_text)
                
                ai_class = int(res_json.get("class", rule_class))
                ai_confidence = float(res_json.get("confidence", 0.85))
                source = "gemini_multimodal_vision"
                logger.info(f"Gemini Vision Result: {ai_class} (Conf: {ai_confidence}) - {res_json.get('analysis')}")
                
            except Exception as e:
                logger.error(f"Gemini Vision fallback failed: {e}")
                ai_class = rule_class
                ai_confidence = 0.85
                source = "mock_hybrid_fallback_failed"

        # --- 4. HYBRID DECISION LOGIC ---
        # final_score = (0.6 * AI_prediction) + (0.4 * Snellen_rule)
        final_score_raw = (0.6 * ai_class) + (0.4 * rule_class)
        # Round to nearest integer class (0 to 3)
        final_class = int(round(final_score_raw))
        # Ensure it stays within bounds
        final_class = max(0, min(3, final_class))
        
        predicted_class_name = cls.CLASS_MAPPING.get(final_class, "Unknown")

        # --- 5. MEDICAL RECOMMENDATION LOGIC ---
        recommendation = "Lakukan pemeriksaan rutin setiap 1 tahun."
        action_required = False
        can_consult_chatbot = False

        if final_class == 1:
            recommendation = "Gangguan ringan terdeteksi. Gunakan kacamata jika terasa mata lelah."
            can_consult_chatbot = True
        elif final_class == 2:
            recommendation = "Miopia terdeteksi. Segera konsultasi ke dokter mata untuk resep kacamata."
            action_required = True
            can_consult_chatbot = True
        elif final_class == 3:
            recommendation = "Gangguan penglihatan SERIUS. Sangat disarankan untuk segera ke spesialis mata!"
            action_required = True
            can_consult_chatbot = True

        return schemas.RefractionAIResultDetail(
            visual_acuity=snellen_fraction,
            snellen_decimal=round(decimal_acuity, 2),
            predicted_class=predicted_class_name,
            confidence=round(ai_confidence, 2),
            recommendation=recommendation,
            action_required=action_required,
            can_consult_chatbot=can_consult_chatbot,
            source=source
        )
