import json
import os
import uuid
import csv
import io
import datetime
from flask import Flask, request, jsonify, render_template, Response

app = Flask(__name__)
DB_FILE = 'database.json'

# Admin Configuration
ADMIN_PASSWORD = "admin" # Change this!

# Default configuration for the auth system
AUTH_CONFIG = {
    "app_name": "KetamineHub",
    "app_id": "ketamine_v1_987654321"
}

def load_db():
    if not os.path.exists(DB_FILE):
        return {"keys": {}}
    with open(DB_FILE, 'r') as f:
        return json.load(f)

def save_db(data):
    with open(DB_FILE, 'w') as f:
        json.dump(data, f, indent=4)

@app.route('/verify', methods=['POST'])
def verify_key():
    data = request.json
    if not data:
        return jsonify({"success": False, "message": "Invalid request"}), 400

    app_id = data.get('app_id')
    key = data.get('key')
    hwid = data.get('hwid')

    if app_id != AUTH_CONFIG['app_id']:
        return jsonify({"success": False, "message": "Invalid App ID!"}), 403

    db = load_db()
    keys = db.get("keys", {})

    if key not in keys:
        return jsonify({"success": False, "message": "Invalid Key!"}), 401

    key_info = keys[key]

    # Check status
    if key_info.get("status") == "paused":
        return jsonify({"success": False, "message": "This key has been paused by the admin."}), 403

    # Check expiration
    expires_at = key_info.get("expires_at")
    if expires_at:
        try:
            exp_date = datetime.datetime.strptime(expires_at, "%Y-%m-%d %H:%M:%S")
            if datetime.datetime.now() > exp_date:
                return jsonify({"success": False, "message": "This key has expired!"}), 403
        except Exception:
            pass

    # Check HWID lock
    if key_info.get("hwid_locked", True):
        if not key_info.get("hwid"):
            # First time use, bind the HWID
            key_info["hwid"] = hwid
            save_db(db)
            return jsonify({"success": True, "message": "Key valid and HWID bound!"}), 200
        else:
            # Check if HWID matches
            if key_info["hwid"] == hwid:
                return jsonify({"success": True, "message": "Key verified!"}), 200
            else:
                return jsonify({"success": False, "message": "HWID mismatch! Key is bound to another device."}), 403
    else:
        # HWID lock is disabled
        return jsonify({"success": True, "message": "Key verified! (HWID Bypass)"}), 200

# -------------------------------------------------------------------
# ADMIN / DASHBOARD ROUTES
# -------------------------------------------------------------------

def check_admin(req):
    auth = req.headers.get('Authorization')
    return auth == ADMIN_PASSWORD

@app.route('/dashboard', methods=['GET'])
def render_dashboard():
    return render_template('dashboard.html')

@app.route('/api/admin/verify', methods=['GET'])
def admin_verify():
    if check_admin(request):
        return jsonify({"success": True})
    return jsonify({"success": False}), 401

@app.route('/api/admin/keys', methods=['GET'])
def get_all_keys():
    if not check_admin(request):
        return jsonify({"success": False, "message": "Unauthorized"}), 401
    db = load_db()
    
    # Auto-update status for expired keys for display purposes
    now = datetime.datetime.now()
    keys = db.get("keys", {})
    changed = False
    for k, v in keys.items():
        if v.get("expires_at"):
            try:
                exp_date = datetime.datetime.strptime(v["expires_at"], "%Y-%m-%d %H:%M:%S")
                if now > exp_date and v.get("status") != "expired":
                    v["status"] = "expired"
                    changed = True
            except Exception:
                pass
    if changed:
        save_db(db)
        
    return jsonify({"success": True, "keys": keys})

@app.route('/generate', methods=['POST'])
def generate_key():
    if not check_admin(request):
        return jsonify({"success": False, "message": "Unauthorized"}), 401
    
    data = request.json or {}
    hwid_locked = data.get("hwid_locked", True)
    duration_days = data.get("duration_days")
    note = data.get("note", "")
    prefix = data.get("prefix", "")

    db = load_db()
    
    # Generate the key string
    base_uuid = str(uuid.uuid4())
    if prefix and prefix.strip():
        new_key = f"{prefix.strip()}-{base_uuid}"
    else:
        new_key = base_uuid
    
    expires_at = None
    if duration_days and int(duration_days) > 0:
        exp_date = datetime.datetime.now() + datetime.timedelta(days=int(duration_days))
        expires_at = exp_date.strftime("%Y-%m-%d %H:%M:%S")
        
    db.setdefault("keys", {})[new_key] = {
        "hwid": None,
        "hwid_locked": hwid_locked,
        "created_at": datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "expires_at": expires_at,
        "note": note,
        "status": "active"
    }
    save_db(db)
    return jsonify({"success": True, "key": new_key, "message": "Key generated successfully!"})

@app.route('/api/admin/reset_hwid', methods=['POST'])
def reset_hwid():
    if not check_admin(request):
        return jsonify({"success": False, "message": "Unauthorized"}), 401
    
    data = request.json
    key = data.get('key')
    db = load_db()
    
    if key in db.get("keys", {}):
        db["keys"][key]["hwid"] = None
        save_db(db)
        return jsonify({"success": True, "message": "HWID reset successfully"})
    return jsonify({"success": False, "message": "Key not found"}), 404

@app.route('/api/admin/toggle_status', methods=['POST'])
def toggle_status():
    if not check_admin(request):
        return jsonify({"success": False, "message": "Unauthorized"}), 401
    
    data = request.json
    key = data.get('key')
    db = load_db()
    
    if key in db.get("keys", {}):
        current = db["keys"][key].get("status", "active")
        new_status = "paused" if current == "active" else "active"
        db["keys"][key]["status"] = new_status
        save_db(db)
        return jsonify({"success": True, "message": f"Key {new_status} successfully"})
    return jsonify({"success": False, "message": "Key not found"}), 404

@app.route('/api/admin/bulk_toggle', methods=['POST'])
def bulk_toggle():
    if not check_admin(request):
        return jsonify({"success": False, "message": "Unauthorized"}), 401
    
    data = request.json
    prefix = data.get('prefix', '').upper()
    action = data.get('action') # 'pause' or 'unpause'
    
    if not prefix:
        return jsonify({"success": False, "message": "Prefix is required"}), 400
        
    db = load_db()
    updated_count = 0
    new_status = "paused" if action == "pause" else "active"
    
    for k, v in db.get("keys", {}).items():
        if prefix in k.upper():
            # Don't unpause expired keys unless they really want to, but standard logic keeps expired expired on load
            if v.get("status") != new_status:
                v["status"] = new_status
                updated_count += 1
                
    if updated_count > 0:
        save_db(db)
        return jsonify({"success": True, "message": f"Successfully {action}d {updated_count} keys."})
    else:
        return jsonify({"success": False, "message": "No keys found matching that prefix."}), 404

@app.route('/api/admin/delete_key', methods=['POST'])
def delete_key():
    if not check_admin(request):
        return jsonify({"success": False, "message": "Unauthorized"}), 401
    
    data = request.json
    key = data.get('key')
    db = load_db()
    
    if key in db.get("keys", {}):
        del db["keys"][key]
        save_db(db)
        return jsonify({"success": True, "message": "Key deleted"})
    return jsonify({"success": False, "message": "Key not found"}), 404

@app.route('/api/admin/export', methods=['GET'])
def export_csv():
    # We pass password via query param for direct browser download
    auth = request.args.get('auth')
    if auth != ADMIN_PASSWORD:
        return jsonify({"success": False, "message": "Unauthorized"}), 401

    db = load_db()
    keys = db.get("keys", {})

    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow(['Key', 'Created At', 'Expires At', 'Status', 'Note', 'HWID Locked', 'HWID'])

    for k, v in keys.items():
        writer.writerow([
            k,
            v.get('created_at', ''),
            v.get('expires_at', 'Lifetime'),
            v.get('status', 'active'),
            v.get('note', ''),
            v.get('hwid_locked', True),
            v.get('hwid', 'None')
        ])

    return Response(
        output.getvalue(),
        mimetype="text/csv",
        headers={"Content-disposition": "attachment; filename=keys_export.csv"}
    )

# -------------------------------------------------------------------
# PUBLIC LOADER ROUTE
# -------------------------------------------------------------------

@app.route('/loader', methods=['GET'])
def serve_loader():
    """
    This endpoint serves the obfuscated CustomLoader.lua to your users.
    Change the path below if you move the file.
    """
    loader_path = r"c:\Users\GuyzModz\Desktop\roblox scripts\CustomLoader_obfuscated.lua"
    if os.path.exists(loader_path):
        with open(loader_path, "r", encoding="utf-8") as f:
            code = f.read()
        return Response(code, mimetype="text/plain")
    return "warn('Loader not found on server! Contact admin.')", 404

if __name__ == '__main__':
    # Initialize DB if missing
    if not os.path.exists(DB_FILE):
        save_db({"keys": {
            "KETAMINE-VIP-PERM": {
                "hwid": None,
                "hwid_locked": True,
                "created_at": datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
                "expires_at": None,
                "note": "Initial VIP Key",
                "status": "active"
            }
        }})
    print(f"Starting Auth Server for {AUTH_CONFIG['app_name']} (App ID: {AUTH_CONFIG['app_id']})")
    app.run(host='0.0.0.0', port=5000, debug=True)
