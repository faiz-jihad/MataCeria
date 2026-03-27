import cv2
import os
import numpy as np
import base64
import logging
from typing import Tuple, List, Optional
from app import schemas

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

class FaceDetectionService:
    # Load cascades & DNN Model
    MODELS_DIR = "/app/app/assets/models"
    PROTOTXT = os.path.join(MODELS_DIR, "deploy.prototxt")
    MODEL = os.path.join(MODELS_DIR, "res10_300x300_ssd_iter_140000.caffemodel")
    
    # DNN Net initialization (Lazy loading)
    _net = None

    FACE_CASCADE = cv2.CascadeClassifier(os.path.join(cv2.data.haarcascades, "haarcascade_frontalface_default.xml"))
    EYE_CASCADE = cv2.CascadeClassifier(os.path.join(cv2.data.haarcascades, "haarcascade_eye.xml"))

    @classmethod
    def get_net(cls):
        if cls._net is None:
            if os.path.exists(cls.PROTOTXT) and os.path.exists(cls.MODEL):
                cls._net = cv2.dnn.readNetFromCaffe(cls.PROTOTXT, cls.MODEL)
                logger.info("Successfully loaded OpenCV DNN Face Detector.")
            else:
                logger.warning("DNN Model files missing. Falling back to Haar Cascades.")
        return cls._net

    @classmethod
    def detect_face_and_eyes(cls, base64_image: str) -> schemas.RefractionAIDetectDistanceResponse:
        """
        Mendeteksi wajah (Robust DNN dengan fallback Haar) dan mata, menghitung Pixel IPD.
        """
        try:
            # 1. Decode Image
            if ',' in base64_image:
                base64_image = base64_image.split(',')[1]
            
            img_data = base64.b64decode(base64_image)
            nparr = np.frombuffer(img_data, np.uint8)
            img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

            if img is None:
                return schemas.RefractionAIDetectDistanceResponse(
                    success=False, pixel_ipd=0.0, face_found=False, message="Gambar tidak terbaca atau rusak."
                )

            h_orig, w_orig = img.shape[:2]
            gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
            
            # --- 2. DETECT FACE (DNN FIRST) ---
            net = cls.get_net()
            face_coords = None # (x, y, w, h)

            if net is not None:
                blob = cv2.dnn.blobFromImage(cv2.resize(img, (300, 300)), 1.0, (300, 300), (104.0, 177.0, 123.0))
                net.setInput(blob)
                detections = net.forward()

                best_conf = 0
                for i in range(detections.shape[2]):
                    confidence = detections[0, 0, i, 2]
                    if confidence > 0.5:
                        if confidence > best_conf:
                            best_conf = confidence
                            box = detections[0, 0, i, 3:7] * np.array([w_orig, h_orig, w_orig, h_orig])
                            (startX, startY, endX, endY) = box.astype("int")
                            # Ensure within bounds
                            startX, startY = max(0, startX), max(0, startY)
                            endX, endY = min(w_orig - 1, endX), min(h_orig - 1, endY)
                            face_coords = (startX, startY, endX - startX, endY - startY)

            # FALLBACK TO HAAR IF DNN FAILED
            if face_coords is None:
                faces_haar = cls.FACE_CASCADE.detectMultiScale(gray, 1.1, 5, minSize=(80, 80))
                if len(faces_haar) > 0:
                    face_coords = sorted(faces_haar, key=lambda f: f[2]*f[3], reverse=True)[0]

            if face_coords is None:
                logger.info("[FaceDetection] Face NOT found (DNN & Haar FAILED)")
                return schemas.RefractionAIDetectDistanceResponse(
                    success=False, pixel_ipd=0.0, face_found=False, message="Wajah tidak terdeteksi (DNN & Haar Gagal)."
                )

            (x, y, w, h) = face_coords
            logger.info(f"[FaceDetection] Face FOUND at [{x}, {y}, {w}, {h}]")
            roi_gray = gray[y:y+h, x:x+w]

            # --- 3. DETECT EYES WITHIN FACE ROI ---
            eyes = cls.EYE_CASCADE.detectMultiScale(roi_gray, 1.1, 8, minSize=(25, 25))

            if len(eyes) < 2:
                # If eyes not found in the large face, maybe too small? 
                # We return face found at least.
                return schemas.RefractionAIDetectDistanceResponse(
                    success=True, 
                    pixel_ipd=0.0, 
                    face_found=True, 
                    landmarks=schemas.RefractionAILandmarks(
                        left_eye=[0, 0], 
                        right_eye=[0, 0], 
                        bounding_box=[float(x), float(y), float(w), float(h)]
                    ),
                    message="Wajah terdeteksi kuat, tapi fitur mata kurang jelas."
                )

            # Sort eyes by X position
            eyes = sorted(eyes, key=lambda e: e[0])
            eye1, eye2 = eyes[0], eyes[1]

            center1 = [float(x + eye1[0] + eye1[2]/2), float(y + eye1[1] + eye1[3]/2)]
            center2 = [float(x + eye2[0] + eye2[2]/2), float(y + eye2[1] + eye2[3]/2)]

            # Calculate Pixel IPD
            pixel_ipd = np.sqrt((center1[0] - center2[0])**2 + (center1[1] - center2[1])**2)

            return schemas.RefractionAIDetectDistanceResponse(
                success=True,
                pixel_ipd=float(pixel_ipd),
                face_found=True,
                landmarks=schemas.RefractionAILandmarks(
                    left_eye=center1,
                    right_eye=center2,
                    bounding_box=[float(x), float(y), float(w), float(h)]
                ),
                message="Wajah (DNN) dan mata berhasil dideteksi."
            )

        except Exception as e:
            logger.error(f"Error in FaceDetectionService: {e}")
            return schemas.RefractionAIDetectDistanceResponse(
                success=False, pixel_ipd=0.0, face_found=False, message=f"Internal Error: {str(e)}"
            )
