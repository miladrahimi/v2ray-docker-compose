#!/usr/bin/python3

import base64
import json
import re
from pathlib import Path
from urllib.request import urlopen

path = Path(__file__).parent
file = open(str(path.joinpath('v2ray/config/config.json')), 'r', encoding='utf-8')
config = json.load(file)

ip = urlopen("https://ipv4.icanhazip.com/").read().decode().rstrip()

for inbound in config['inbounds']:
    if inbound['protocol'] == 'vless':
        port = str(inbound['port'])
        uuid = inbound['settings']['clients'][0]['id']
        sni = inbound['streamSettings']['realitySettings']['serverNames'][0]
        link = "vless://{}@{}:{}?type=tcp&security=reality&headerType=none&fp=firefox&sni={}&flow=xtls-rprx-vision&pbk=CbcY9qc4YuMDJDyyL0OITlU824TBg1O84ClPy27e2RM#{}:{}".format(uuid, ip, port, sni, ip, port)
        print("\nVLESS:\n" + link)
