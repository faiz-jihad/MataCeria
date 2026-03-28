import requests
import json

base_url = "http://localhost:8000/api/v1"

def test_refraction(test_name, payload):
    print(f"\n--- Testing: {test_name} ---")
    response = requests.post(f"{base_url}/refraction/test", json=payload)
    if response.status_code == 200:
        print(json.dumps(response.json(), indent=2))
    else:
        print(f"Error {response.status_code}: {response.text}")

# 1. Test Miopia (Normal Distance)
test_refraction("Miopia (Distance Vision - Low Acuity)", {
    "user_id": "1",
    "test_type": "distance_vision",
    "device_info": {"screen_ppi": 400, "screen_width_px": 1080},
    "raw_data": {
        "avg_distance_cm": 300,
        "smallest_row_read": 3,
        "missed_chars": 0
    }
})

# 2. Test Hypermetropia (Near Vision - Low Acuity)
test_refraction("Hypermetropia (Near Vision - Low Acuity)", {
    "user_id": "1",
    "test_type": "near_vision",
    "device_info": {"screen_ppi": 400, "screen_width_px": 1080},
    "raw_data": {
        "avg_distance_cm": 40,
        "smallest_row_read": 4,
        "missed_chars": 0
    }
})

# 3. Test Astigmatism
test_refraction("Astigmatism Found", {
    "user_id": "1",
    "test_type": "distance_vision",
    "device_info": {"screen_ppi": 400, "screen_width_px": 1080},
    "raw_data": {
        "avg_distance_cm": 300,
        "smallest_row_read": 8,
        "missed_chars": 0,
        "astigmatism_found": True
    }
})
