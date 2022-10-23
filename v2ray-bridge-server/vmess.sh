#!/bin/sh

REAL_IP=$(curl -s -m 5 ifconfig.io)
printf "BRIDGE-IP (Leave empty to use '%s'): " "$REAL_IP"
read -r IP
IP=${IP:-$REAL_IP}

printf "BRIDGE-PORT (Leave empty to use '%s'): " "1310"
read -r PORT
PORT=${PORT:-1310}

printf "BRIDGE-UUID: "
read -r UUID

JSON="{\"add\": \"$IP\", \"aid\": \"0\", \"host\": \"\", \"id\": \"$UUID\", \"net\": \"tcp\", \"path\": \"\", \
\"port\": \"$PORT\", \"ps\": \"$IP/tcp\", \"tls\": \"\", \"type\": \"none\", \"v\": \"2\"}"

printf "\n%s:\n%s%s\n" "VMESS Link" "vmess://" "$(echo "$JSON" | base64 -w 0)"
