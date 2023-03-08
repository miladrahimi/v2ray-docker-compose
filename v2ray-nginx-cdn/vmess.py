#!/usr/bin/python3

import base64
import yaml
import json
from pathlib import Path
import urllib.request

def config_generator(domain, uuid, ip=""):
    if ip == "":
        ip = domain
    name = domain
    j = json.dumps({
        "v": "2", "ps": name, "add": ip, "port": "443", "id": uuid,
        "aid": "0", "net": "ws", "type": "none", "sni": domain,
        "host": domain, "path": "/", "tls": "tls"
    })
    return("vmess://" + base64.b64encode(j.encode('ascii')).decode('ascii'))


path = Path(__file__).parent
v2ray_config_file = open(str(path.joinpath('v2ray/config/config.json')), 'r', encoding='utf-8')
v2ray_config = json.load(v2ray_config_file)
with open(str(path.joinpath('docker-compose.yml')), 'r') as f:
    dockerCompose = yaml.safe_load(f)

uuid = v2ray_config['inbounds'][0]['settings']['clients'][0]['id']
domain = dockerCompose["services"]["v2ray"]["environment"][1].split('=')[1];
isUsingCloudFlareCDNProxy = 'no'

isUsingCloudFlareCDNProxy = input("Are you using CloudFlare CDN Proxy? type 'yes' or 'no'. Default is no.\n")
if isUsingCloudFlareCDNProxy == 'yes':
    enhancedIPList = []
    for line in open(str(path.joinpath('cloudflare_ip_list.txt')), 'r'):
        print(config_generator(domain, uuid, line + "\n"))
else:
    print(config_generator(domain, uuid))
