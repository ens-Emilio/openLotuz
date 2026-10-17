#!/usr/bin/env python3
# lotuz-crm — consulta Atomic CRM via PostgREST (nginx local)
import os, sys, json, urllib.request

ANON = os.getenv("ANON_KEY") or ""
BASE = "http://127.0.0.1:3000/rest/v1"

def req(path):
    r = urllib.request.Request(BASE + path, headers={"apikey": ANON, "Accept": "application/json"})
    with urllib.request.urlopen(r, timeout=15) as resp:
        return json.loads(resp.read())

if len(sys.argv) < 2:
    print("uso: lotuz-crm [companies|contacts|deals]")
    sys.exit(1)

cmd = sys.argv[1]
try:
    if cmd == "companies":
        data = req("/companies?select=id,name,created_at&order=created_at.desc&limit=20")
    elif cmd == "contacts":
        data = req("/contacts?select=id,first_name,last_name,email,company_id&order=created_at.desc&limit=20")
    elif cmd == "deals":
        data = req("/deals?select=id,name,stage,value,company_id&order=created_at.desc&limit=20")
    else:
        print("comando desconhecido")
        sys.exit(1)
    print(json.dumps(data, indent=2, ensure_ascii=False))
except Exception as e:
    print(f"erro: {e}")