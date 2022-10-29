#!/bin/bash

#Validate settings
jq_command=$(which jq)
[ -z $jq_command ] && { printf "Install 'jq' via your package manager (e.g. 'apt install jq') and try again.\n"; exit 1; }
CONFIG_JSON="config/config.json"
[ -f "$CONFIG_JSON" ] || { printf "Error: cannot find config/config.json."; exit 1; }

# Getting the public IP address
IP=$(curl -s ident.me)
printf "Enter IP address (Leave empty to use '%s'): " "$IP"
read -r INPUT_IP
[ -n "$INPUT_IP" ] && IP="$INPUT_IP"

# Parse the vmess configuration
VMESS_CONFIG=$(jq -r '.inbounds[] | select(.protocol == "vmess")' "$CONFIG_JSON")

# Parse port and streamSettings
PORT=$(echo "$VMESS_CONFIG" | jq -r .port)
STREAM_SETTINGS=$(echo "$VMESS_CONFIG" | jq -r .streamSettings.network)

# For each configured client, generate a vmess link
CLIENTS=$(echo "$VMESS_CONFIG" | jq -r .settings.clients[])
for CLIENT in "$CLIENTS"; do
    UUID=$(echo "$CLIENT" | jq -r .id)
    ALERT_ID=$(echo "$CLIENT" | jq -r .alterId)
    JSON="{\"add\": \"$IP\", \"aid\": \"$ALERT_ID\", \"host\": \"\", \"id\": \"$UUID\", \"net\": \"$STREAM_SETTINGS\", \
            \"path\": \"\", \"port\": \"$PORT\", \"ps\": \"$IP/$PORT\", \"tls\": \"\", \"type\": \"none\", \"v\": \"2\"}"
    printf "\n%s:\n%s%s\n" "VMESS Link" "vmess://" "$(echo "$JSON" | base64 -w 0)"
done
