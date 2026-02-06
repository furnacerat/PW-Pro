
import urllib.request
import urllib.parse
import json
import plistlib
import ssl
import sys
import uuid
from datetime import datetime

# --- Configuration ---
CONFIG_PATH = "PWProApp/PWProApp/Config.plist"

def load_config():
    try:
        with open(CONFIG_PATH, 'rb') as f:
            pl = plistlib.load(f)
            return pl['SUPABASE_URL'], pl['SUPABASE_ANON_KEY']
    except Exception as e:
        print(f"❌ Failed to load config: {e}")
        sys.exit(1)

URL, KEY = load_config()
HEADERS = {
    "apikey": KEY,
    "Authorization": f"Bearer {KEY}",
    "Content-Type": "application/json",
    "Prefer": "return=representation"
}

# --- Helpers ---
def make_request(endpoint, method="GET", data=None, token=None):
    if endpoint.startswith("auth"):
        full_url = f"{URL}/{endpoint}"
    else:
        full_url = f"{URL}/rest/v1/{endpoint}"
    
    headers = HEADERS.copy()
    if token:
        headers["Authorization"] = f"Bearer {token}"
        
    if data:
        json_data = json.dumps(data).encode('utf-8')
    else:
        json_data = None
        
    req = urllib.request.Request(full_url, data=json_data, headers=headers, method=method)
    
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE
    
    try:
        with urllib.request.urlopen(req, context=ctx) as response:
            if response.status >= 200 and response.status < 300:
                resp_data = response.read()
                if resp_data:
                    return json.loads(resp_data.decode())
                return {}
            else:
                print(f"❌ {method} {endpoint} failed: {response.status}")
                return None
    except urllib.error.HTTPError as e:
        # Auth endpoints return 400/422 for existing user, which we handle
        if endpoint.startswith("auth") and e.code in [400, 422]:
            return {"error": e.code, "message": e.read().decode()}
        print(f"❌ {method} {endpoint} failed: {e.code} - {e.read().decode()}")
        return None
    except Exception as e:
        print(f"❌ Request failed: {e}")
        return None

# --- Auth ---
def authenticate():
    print("Authenticate...")
    # Use unique email to bypass 'User already registered' and potential state issues
    email = f"smoke_{str(uuid.uuid4())[:8]}@test.com"
    password = "password123"
    
    print(f"   Attempting Signup as {email}...")
    # 1. Try Signup
    res = make_request("auth/v1/signup", "POST", {"email": email, "password": password})
    
    if res and "access_token" in res:
        print("   ✅ Signed Up & Authenticated")
        return res["user"]["id"], res["access_token"]
    
    # If no token, check if we got a user object but no session (Email Confirm required)
    if res and "user" in res and "access_token" not in res:
        print("   ⚠️ Signup succeeded but no session returned. Email confirmation likely required.")
        return None, None
    
    print(f"   ⚠️ Signup response did not contain token. Response: {res}")

    # 2. Fallback (unlikely to reach here with unique email unless blocked)
    print("   User exists, logging in...")
    res = make_request("auth/v1/token?grant_type=password", "POST", {"email": email, "password": password})
    
    if res and "access_token" in res:
        print("   ✅ Logged In")
        return res["user"]["id"], res["access_token"]
    
    print(f"   ❌ Auth Failed: {res}")
    return None, None

# --- Tests ---
def test_connection():
    print("Testing Supabase Connection...")
    res = make_request("clients?select=count", method="GET")
    # 401 is okay here for anon key if RLS blocks read-all, but we just check if endpoint responds
    if res is not None: 
        print("✅ Connection Verified")
        return True
    return False

def test_client_crud(user_id, token):
    print("\nTesting Client CRUD...")
    
    test_id = str(uuid.uuid4())
    new_client = {
        "id": test_id,
        "user_id": user_id,
        "name": "Smoke Test Client",
        "email": "smoke@test.com",
        "rating": 5,
        "total_spent": 0,
        "lifetime_jobs": 0
    }
    
    print("   Creating Client...")
    res = make_request("clients", "POST", new_client, token=token)
    if res and res[0]['id'] == test_id:
        print("   ✅ Created")
    else:
        print("   ❌ Create Failed")
        return False
        
    print("   Reading Client...")
    res = make_request(f"clients?id=eq.{test_id}&select=*", "GET", token=token)
    if res and res[0]['name'] == "Smoke Test Client":
        print("   ✅ Read Verified")
    else:
        print("   ❌ Read Failed")
        return False
        
    print("   Updating Client...")
    update_data = {"name": "Smoke Test Updated"}
    res = make_request(f"clients?id=eq.{test_id}", "PATCH", update_data, token=token)
    if res and res[0]['name'] == "Smoke Test Updated":
        print("   ✅ Update Verified")
    else:
        print("   ❌ Update Failed")
        return False
        
    print("   Deleting Client...")
    res = make_request(f"clients?id=eq.{test_id}", "DELETE", token=token)
    res = make_request(f"clients?id=eq.{test_id}", "GET", token=token)
    if res == []:
        print("   ✅ Delete Verified")
    else:
        print("   ❌ Delete Failed")
        return False
        
    return True

def test_chemicals_access(token):
    print("\nTesting Chemical Inventory Access...")
    # Using token to verify RLS allows read for user
    res = make_request("chemical_inventory?limit=1", "GET", token=token)
    if res is not None:
        print(f"   ✅ Chemicals Table Accessible (Row count: {len(res)})")
        return True
    return False

def main():
    print(f"Starting Backend Smoke Test...")
    print(f"Target: {URL}")
    print("--------------------------------")
    
    if not test_connection():
        print("\n❌ Smoke Test Aborted: No Connection")
        return
        
    user_id, token = authenticate()
    if not token:
        print("\n❌ Smoke Test Aborted: Auth Failed")
        return
        
    if test_client_crud(user_id, token):
        print("✅ Client CRUD Passed")
    else:
        print("❌ Client CRUD Failed")
        
    if test_chemicals_access(token):
        print("✅ Chemicals Access Passed")
        
    print("\n--------------------------------")
    print("Smoke Test Complete.")

if __name__ == "__main__":
    main()
