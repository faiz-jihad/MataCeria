import requests
import json

BASE_URL = "http://localhost:8000/api/v1"

def test_enhancements():
    print("--- 1. Login Admin ---")
    login_data = {"username": "admin@refraksi.com", "password": "admin123"}
    resp = requests.post(f"{BASE_URL}/auth/login", data=login_data)
    token = resp.json().get("access_token")
    headers = {"Authorization": f"Bearer {token}"}
    print(f"Token obtained.")

    print("\n--- 2. Test Medical Research Search ---")
    # Search for something related to myopia
    resp = requests.get(f"{BASE_URL}/articles/research-search?query=penelitian+miopia")
    print(f"Search Status: {resp.status_code}")
    print(f"Sample Result: {resp.json().get('results')[:200]}...")

    print("\n--- 3. Test Static File Access ---")
    # Check if /uploads/ is accessible (should return 404 or something if file not exists, but path should be mounted)
    resp = requests.get("http://localhost:8000/uploads/test.txt")
    print(f"Static Access Status (Expected 404 if file missing, but valid mount): {resp.status_code}")

    print("\n--- 4. Test User Deletion ---")
    # Create a dummy user first
    reg_data = {
        "nama_lengkap": "User To Delete",
        "email": "delete_me@example.com",
        "password": "password123",
        "umur": 20,
        "kelamin": "Laki-laki",
        "jenjang_pendidikan": "SMA",
        "status_pekerjaan": "Pelajar/Mahasiswa"
    }
    requests.post(f"{BASE_URL}/auth/register", json=reg_data)
    
    # Find the ID (we can get it from export or database later, but let's assume we can find it)
    export_resp = requests.get(f"{BASE_URL}/admin/users/export", headers=headers)
    users = export_resp.json().get("data", [])
    target_id = None
    for u in users:
        if u['email'] == "delete_me@example.com":
            target_id = u['id']
            break
    
    if target_id:
        print(f"Deleting User ID: {target_id}")
        del_resp = requests.delete(f"{BASE_URL}/admin/users/{target_id}", headers=headers)
        print(f"Delete Status: {del_resp.status_code}")
    else:
        print("User to delete not found.")

if __name__ == "__main__":
    test_enhancements()
