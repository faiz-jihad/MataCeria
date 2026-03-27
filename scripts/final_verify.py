import requests
import json

BASE_URL = "http://localhost:8000/api/v1"

def final_test():
    print("--- Login Admin ---")
    login_data = {"username": "admin@refraksi.com", "password": "admin123"}
    resp = requests.post(f"{BASE_URL}/auth/login", data=login_data)
    token = resp.json().get("access_token")
    headers = {"Authorization": f"Bearer {token}"}

    print("\n--- Test Admin Stats ---")
    resp = requests.get(f"{BASE_URL}/admin/stats/overview", headers=headers)
    print(f"Stats Status: {resp.status_code}")
    print(f"Stats Data: {resp.json()}")

    print("\n--- Test Admin User List ---")
    resp = requests.get(f"{BASE_URL}/admin/users", headers=headers)
    print(f"User List Status: {resp.status_code}")
    users = resp.json()
    print(f"Total Users Found: {len(users)}")
    if users:
        print(f"First User Sample: {users[0]['email']}")

if __name__ == "__main__":
    final_test()
