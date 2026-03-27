import requests
import base64
import json
import os

BASE_URL = "http://localhost:8000/api/v2/refraction"

def test_distance_detection():
    # Buat gambar dummy hitam 300x300 untuk test (seharusnya gagal deteksi wajah tapi endpoint 200)
    import numpy as np
    import cv2
    dummy_img = np.zeros((300, 300, 3), dtype=np.uint8)
    _, buffer = cv2.imencode(".jpg", dummy_img)
    img_base64 = base64.b64encode(buffer).decode("utf-8")

    payload = {
        "image": img_base64,
        "device_info": {"test": True}
    }

    print("--- Testing /detect-distance ---")
    try:
        resp = requests.post(f"{BASE_URL}/detect-distance", json=payload)
        print(f"Status: {resp.status_code}")
        data = resp.json()
        print(f"Success Field: {data.get('success')}")
        print(f"Face Found: {data.get('face_found')}")
        print(f"Message: {data.get('message')}")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    test_distance_detection()
