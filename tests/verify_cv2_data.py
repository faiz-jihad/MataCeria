import cv2
import os

print(f"OpenCV data path: {cv2.data.haarcascades}")
face_cascade_path = os.path.join(cv2.data.haarcascades, "haarcascade_frontalface_default.xml")
eye_cascade_path = os.path.join(cv2.data.haarcascades, "haarcascade_eye.xml")

print(f"Face cascade exists: {os.path.exists(face_cascade_path)}")
print(f"Eye cascade exists: {os.path.exists(eye_cascade_path)}")
