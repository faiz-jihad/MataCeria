import requests
import json

base_url = "http://localhost:8000/api/v1/refraction/test"
headers = {"Content-Type": "application/json"}

# Test 1: Success (Normal Vision)
payload1 = {
  "user_id": "test-123",
  "test_type": "near_vision",
  "device_info": {
    "screen_ppi": 400.0,
    "screen_width_px": 1080
  },
  "raw_data": {
    "avg_distance_cm": 40.0,
    "smallest_row_read": 8,
    "missed_chars": 0
  }
}
print("Test 1: Normal Vision Payload")
response1 = requests.post(base_url, headers=headers, json=payload1)
print(f"Status Code: {response1.status_code}")
print(json.dumps(response1.json(), indent=2))
print("-" * 30)

# Test 2: Validation Error (Distance < 30)
payload2 = {
  "user_id": "test-123",
  "test_type": "near_vision",
  "device_info": {
    "screen_ppi": 400.0,
    "screen_width_px": 1080
  },
  "raw_data": {
    "avg_distance_cm": 20.0,
    "smallest_row_read": 8,
    "missed_chars": 0
  }
}
print("Test 2: Validation Error Payload (Distance 20cm)")
response2 = requests.post(base_url, headers=headers, json=payload2)
print(f"Status Code: {response2.status_code}")
print(json.dumps(response2.json(), indent=2))
print("-" * 30)
