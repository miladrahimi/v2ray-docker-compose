#!/bin/sh

REAL_IP=$(curl -s -m 5 ifconfig.io)
printf "BRIDGE-IP (Leave empty to use '%s'): " "$REAL_IP"
read -r IP
IP=${IP:-$REAL_IP}

printf "BRIDGE-PORT (Leave empty to use '%s'): " "1210"
read -r PORT
PORT=${PORT:-1210}

printf "SHADOWSOCKS-ENCRYPTION (Leave empty to use '%s'): " "aes-128-gcm"
read -r SS_ENCRYPTION
SS_ENCRYPTION=${SS_ENCRYPTION:-aes-128-gcm}

printf "SHADOWSOCKS-PASSWORD: "
read -r SS_PASSWORD

printf "ss://%s@%s:%s\n" "$(echo "$SS_ENCRYPTION:$SS_PASSWORD" | base64)" "$IP" "$PORT"
