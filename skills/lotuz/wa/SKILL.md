---
name: lotuz-wa
description: Consultar sessão OpenWA e enviar mensagens WhatsApp somente após confirmação
allowed-tools: Bash(lotuz-wa:*)
---

Use `lotuz-wa status` or `lotuz-wa qr` for session state. Before `lotuz-wa send <number> <message>`, show the exact recipient and message to the user and require explicit confirmation. Never send bulk or unsolicited messages.
