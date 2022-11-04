#!/usr/bin/python3

import base64
import json
import re
from pathlib import Path
from urllib.request import urlopen

path = Path(__file__).parent
file = open(str(path.joinpath('config/config.json')), 'r', encoding='utf-8')
config = json.load(file)

with open(str(path.joinpath('web/index.html')), 'r', encoding="utf-8") as f:
    html = f.read()

ip = urlopen("http://ifconfig.io/ip").read().decode().rstrip()

for inbound in config['inbounds']:
    if inbound['protocol'] == 'socks':
        print("SOCKS: 127.0.0.1:{}".format(str(inbound['port'])))
    if inbound['protocol'] == 'http':
        print("HTTP: 127.0.0.1:{}".format(str(inbound['port'])))
    if inbound['protocol'] == 'shadowsocks':
        port = str(inbound['port'])
        method = inbound['settings']['method']
        password = inbound['settings']['password']
        security = base64.b64encode((method + ":" + password).encode('ascii')).decode('ascii')
        link = "ss://{}@{}:{}#{}:{}".format(security, ip, port, ip, port)
        print("\nShadowsocks:\n" + link)
        ss_link_tag = f'<textarea title="Access key" readonly>{link}</textarea>'
        html = re.sub(r'(<div id="ss-link">)([\s\S]*?)(</div>)', f'\\1\n            {ss_link_tag}\n        \\3', html)
    if inbound['protocol'] == 'vmess':
        port = str(inbound['port'])
        for i, client in enumerate(inbound['settings']['clients'], 1):
            uuid = client['id']
            security = client['security']
            aid = client.get('alterId', "0")
            ps = "{}:{}".format(ip, port)
            c = {"add": ip, "aid": aid, "host": "", "id": uuid, "net": "tcp", "path": "", "port": port, "ps": ps,
                "tls": "none", "type": "none", "v": "2"}
            j = json.dumps(c)
            link = "vmess://" + base64.b64encode(j.encode('ascii')).decode('ascii')
            vmess_links_position = re.search(r'<div id="vmess-links">[\s\S]*</div>', html).end() - 6
            link_tag = f'    <textarea title="VMESS Link" readonly>{link}</textarea>\n        '
            if link_tag.strip() not in html:
                html = html[:vmess_links_position] + link_tag + html[vmess_links_position:]
            print(f"\nVMESS Client{i}:\n{link}")

with open(str(path.joinpath('web/index.html')), 'w', encoding='utf-8') as f:
    f.write(html)
