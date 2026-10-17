#!/usr/bin/env python3
# lotuz-wa — envia WhatsApp via OpenWA (configure WA_URL via env)
import os, sys, json, urllib.request

WA_URL = os.getenv("WA_URL", "https://wa.example.com")

def req(path, data=None, method="GET"):
    url = WA_URL + path
    headers = {"Content-Type": "application/json"}
    body = json.dumps(data).encode() if data else None
    r = urllib.request.Request(url, data=body, headers=headers, method=method)
    with urllib.request.urlopen(r, timeout=15) as resp:
        return json.loads(resp.read())

if len(sys.argv) < 2:
    print("uso: lotuz-wa [send|status|qr]")
    sys.exit(1)

cmd = sys.argv[1]
try:
    if cmd == "status":
        print(json.dumps(req("/status"), indent=2))
    elif cmd == "qr":
        print(json.dumps(req("/qr"), indent=2))
    elif cmd == "send":
        if len(sys.argv) < 4:
            print("uso: lotuz-wa send <number> <message>")
            sys.exit(1)
        number = sys.argv[2]
        message = " ".join(sys.argv[3:])
        print(json.dumps(req("/send-message", {"chatId": number + "@c.us", "content": message}, "POST"), indent=2))
    else:
        print("comando desconhecido")
except Exception as e:
    print(f"erro: {e}")
