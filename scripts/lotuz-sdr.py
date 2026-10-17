#!/usr/bin/env python3
# lotuz-sdr — sequências/mensagens AgentSDR (configure SDR_URL via env)
import os, sys, json, urllib.request

SDR_URL = os.getenv("SDR_URL", "https://sdr.example.com")

def req(path, data=None):
    url = SDR_URL + path
    headers = {"Content-Type": "application/json"}
    body = json.dumps(data).encode() if data else None
    r = urllib.request.Request(url, data=body, headers=headers, method="POST" if data else "GET")
    with urllib.request.urlopen(r, timeout=15) as resp:
        return json.loads(resp.read())

if len(sys.argv) < 2:
    print("uso: lotuz-sdr [send|sequences] [args...]")
    sys.exit(1)

cmd = sys.argv[1]
try:
    if cmd == "sequences":
        print(json.dumps(req("/api/v1/sequences"), indent=2))
    elif cmd == "send":
        if len(sys.argv) < 4:
            print("uso: lotuz-sdr send <sequence_id> <lead_email>")
            sys.exit(1)
        print(json.dumps(req(f"/api/v1/sequences/{sys.argv[2]}/send", {"lead_email": sys.argv[3]}), indent=2))
    else:
        print("comando desconhecido")
except Exception as e:
    print(f"erro: {e}")
