#!/usr/bin/env python3
# lotuz-mkt — campanhas Helio (configure MKT_URL via env)
import os, sys, json, urllib.request

MKT_URL = os.getenv("MKT_URL", "https://mkt.example.com")

def req(path, data=None, method="GET"):
    url = MKT_URL + path
    headers = {"Content-Type": "application/json"}
    body = json.dumps(data).encode() if data else None
    r = urllib.request.Request(url, data=body, headers=headers, method=method)
    with urllib.request.urlopen(r, timeout=15) as resp:
        return json.loads(resp.read())

if len(sys.argv) < 2:
    print("uso: lotuz-mkt [campaigns|create] [args...]")
    sys.exit(1)

cmd = sys.argv[1]
try:
    if cmd == "campaigns":
        print(json.dumps(req("/api/campaigns"), indent=2))
    elif cmd == "create":
        if len(sys.argv) < 4:
            print("uso: lotuz-mkt create <name> <subject>")
            sys.exit(1)
        print(json.dumps(req("/api/campaigns", {"name": sys.argv[2], "subject": sys.argv[3]}, "POST"), indent=2))
    else:
        print("comando desconhecido")
except Exception as e:
    print(f"erro: {e}")
