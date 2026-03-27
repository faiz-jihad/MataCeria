import requests
import os

MODELS_DIR = "/app/app/assets/models"
os.makedirs(MODELS_DIR, exist_ok=True)

urls = {
    "deploy.prototxt": "https://raw.githubusercontent.com/opencv/opencv/master/samples/dnn/face_detector/deploy.prototxt",
    "res10_300x300_ssd_iter_140000.caffemodel": "https://raw.githubusercontent.com/opencv/opencv_3rdparty/dnn_samples_face_detector_20170830/res10_300x300_ssd_iter_140000.caffemodel"
}

for filename, url in urls.items():
    path = os.path.join(MODELS_DIR, filename)
    print(f"Downloading {filename}...")
    try:
        r = requests.get(url, stream=True, timeout=30)
        r.raise_for_status()
        with open(path, "wb") as f:
            for chunk in r.iter_content(chunk_size=8192):
                f.write(chunk)
        print(f"Success: {path}")
    except Exception as e:
        print(f"Failed {filename}: {e}")
