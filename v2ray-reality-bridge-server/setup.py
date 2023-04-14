#!/usr/bin/python3

import uuid
import json
import secrets
from pathlib import Path

# LOAD CONFIG FILE

path = Path(__file__).parent
file = open(str(path.joinpath('v2ray/config/config.json')), 'r', encoding='utf-8')
config = json.load(file)

# CONFIGURE OUTBOUNDS

# INPUT: UPSTREAM-IP

defaultUpstreamIP = config['outbounds'][0]['settings']['vnext'][0]['address']
if defaultUpstreamIP == '<UPSTREAM-IP>':
    message = "Upstream IP:\n"
else:
    message = f"Upstream IP: (Leave empty to use `{defaultUpstreamIP}`)\n"

upstreamIP = input(message)
if upstreamIP != '':
    config['outbounds'][0]['settings']['vnext'][0]['address'] = upstreamIP

# INPUT: UPSTREAM-UUID

defaultUpstreamUUID = config['outbounds'][0]['settings']['vnext'][0]['users'][0]['id']
if defaultUpstreamUUID == '<UPSTREAM-UUID>':
    message = "Upstream UUID:\n"
else:
    message = f"Upstream UUID: (Leave empty to use `{defaultUpstreamUUID}`)\n"

upstreamUUID = input(message)
if upstreamUUID != '':
    config['outbounds'][0]['settings']['vnext'][0]['users'][0]['id'] = upstreamUUID

# INPUT: UPSTREAM-SHORTID

defaultUpstreamShortID = config['outbounds'][0]['streamSettings']['realitySettings']['shortIds'][0]
if defaultUpstreamShortID == '<UPSTREAM-SHORTID>':
    message = "Upstream ShortId:\n"
else:
    message = f"Upstream ShortId: (Leave empty to use `{defaultUpstreamShortID}`)\n"

UpstreamShortID = input(message)
if UpstreamShortID != '':
    config['outbounds'][0]['streamSettings']['realitySettings']['shortIds'][0] = UpstreamShortID


# CONFIGURE INBOUNDS

defaultUUID = config['inbounds'][0]['settings']['clients'][0]['id']
if defaultUUID == '<BRIDGE-UUID>':
    message = "Bridge UUID:\n"
else:
    message = f"Bridge UUID: (Leave empty to use `{defaultUUID}`)\n"

bridgeUUID = input(message)
if bridgeUUID == "":
    if defaultUUID == '<BRIDGE-UUID>':
        bridgeUUID = str(uuid.uuid4())
    else:
        bridgeUUID = defaultUUID

config['inbounds'][0]['settings']['clients'][0]['id'] = bridgeUUID

# INPUT: <BRIDGE-SHORTID>

defaultBridgeShortID = config['inbounds'][0]['streamSettings']['realitySettings']['shortIds'][0]
if defaultBridgeShortID == '<BRIDGE-SHORTID>':
    message = "Bridge ShortId:\n"
else:
    message = f"Bridge ShortId: (Leave empty to use `{defaultBridgeShortID}`)\n"

BridgeShortID = input(message)
if BridgeShortID != '':
    config['inbounds'][0]['streamSettings']['realitySettings']['shortIds'][0] = BridgeShortID



# SAVE CONFIG FILE

content = json.dumps(config, indent=2)
open(str(path.joinpath('v2ray/config/config.json')), 'w', encoding='utf-8').write(content)

# PRINT OUT RESULT

print('Done!')
