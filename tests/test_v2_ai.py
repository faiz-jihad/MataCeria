import requests
import base64
import os

url = "http://localhost:8000/api/v2/refraction/ai"
headers = {"Content-Type": "application/json"}

# 1x1 dummy black pixel base64
mock_base64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII="

payload = {
    "user_id": "1",
    "device_info": {
        "screen_ppi": 300.0
    },
    "snellen_data": {
        "avg_distance_cm": 40.0,
        "smallest_row_read": 5, 
        "missed_chars": 1,
        "response_time": 1.2
    },
    "image_data": {
        "eye_frame_base64": mock_base64
    }
}

print(f"Testing {url}...")
try:
    response = requests.post(url, json=payload)
    print("Status Code:", response.status_code)
    try:
        print("Response JSON:", response.json())
    except Exception as e:
        print("Response Text:", response.text)
except requests.exceptions.RequestException as e:
    print(f"Request failed: {e}")
