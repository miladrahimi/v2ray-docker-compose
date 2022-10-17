# V2Ray Docker Compose

This repository contains sample Docker Compose files to run V2Ray upstream and bridge servers.

## Documentation

### Terminology

* Upstream Server: A server that has free access to the Internet.
* Bridge Server: A server that is available to clients and has access to the upstream server.
* Client: A user-side application with access to the bridge server.

```
(Client) <-> [ Bridge Server ] <-> [ Upstream Server ] <-> (Internet)
```

### Setup

#### UUIDs

V2Ray uses the VMESS protocol as the primary protocol.
The VMESS protocol requires UUIDs for security reasons (instead of passwords).
We need two UUIDs for the two V2Ray servers (upstream and bridge servers).

You can generate UUIDs using:
* This Linux command: ```cat /proc/sys/kernel/random/uuid```
* This online tool: [https://www.uuidgenerator.net](https://www.uuidgenerator.net)

Sample generated UUIDs:
* `cfc3ac34-a70d-424e-b43c-33049cf4bf31`
* `143d98d8-ac89-465a-acb5-d8d51e1f851f`

#### Upstream Server

To setup the upstream server:
1. Copy the "v2ray-upstream-server" directory into the upstream server.
2. Replace `<UPSTREAM-UUID>` in the `config.json` file with one of the generated UUIDs.
3. Run `docker-compose up -d`.

#### Bridge Server

To setup the bridge server:
1. Copy the "v2ray-bridge-server" directory into the bridge server.
2. Replace the following variables in the `config.json` file with appropriate values.
    * `<SHADOWSOCKS-PASSWORD>`: A password for Shadowsocks users like `!FR33DoM!`.
    * `<SOCKS-USERNAME>`: A username for SOCKS5 proxy like `myuser`.
    * `<SOCKS-PASSWORD>`: A password for SOCKS5 proxy `!FR33DoM!`.
    * `<BRIDGE-UUID>`: The generated UUID for the bridge server.
    * `<UPSTREAM-IP>`: The upstream server IP address like `13.13.13.13`.
    * `<UPSTREAM-UUID>`: The used UUID for the upstream server.
3. Run `docker-compose up -d`. 

#### Clients

The bridge server exposes these proxy protocols:
* Shadowsocks
* VMESS
* HTTP
* SOCKS

##### Shadowsocks Protocol

Shadowsocks is a popular proxy protocol.
You can find many client apps to use the Shadowsocks proxy on your devices.
These are recommended client apps:
* [Qv2ray](https://qv2ray.net) (macOS, Linux and Windows)
* [Shadowsocks for macOS](https://github.com/shadowsocks/ShadowsocksX-NG/releases)
* [Shadowsocks for Linux](https://github.com/shadowsocks/shadowsocks-libev)
* [Shadowsocks for Windows](https://github.com/shadowsocks/shadowsocks-windows/releases)
* [Shadowsocks for Android](https://github.com/shadowsocks/shadowsocks-android/releases)
* [ShadowLink for iOS](https://apps.apple.com/us/app/shadowlink-shadowsocks-vpn/id1439686518)

Client configuration:
```
IP Address: <BRIDGE-IP>
Port: 1210
Encryption/Method/Algorithm: aes-128-gcm
Password: <SHADOWSOCKS-PASSWORD>
```

##### VMESS Protocol

The VMESS proxy protocol is the recommended one.
It's the primary protocol that V2Ray provides.
These are recommended client apps:
* [Qv2ray](https://qv2ray.net) (macOS, Linux and Windows)
* [V2RayX for macOS](https://github.com/Cenmrev/V2RayX/releases)
* [v2ray-core for Linux](https://github.com/v2ray/v2ray-core)
* [v2rayN for Windows](https://github.com/2dust/v2rayN/releases)
* [ShadowLink for iOS](https://apps.apple.com/us/app/shadowlink-shadowsocks-vpn/id1439686518)
* [v2rayNG for Android](https://github.com/2dust/v2rayNG)

Client configuration:
```
IP Address: <BRIDGE-IP>
Port: 1310
ID/UUID/UserID: <BRIDGE-UUID>
Alter ID: 10
Level: 0
Security/Method/Encryption: aes-128-gcm
Network: TCP
```

##### HTTP & SOCKS Protocols

Moved here: [HTTP_SOCKS_PROTOCOLS.md](HTTP_SOCKS_PROTOCOLS.md)

### Docker images

We cannot pull docker images from Docker Hub here in Iran.
Therefore I've pushed the official V2Ray Docker image into the GitHub image registry.
If you prefer pulling the image from the Docker Hub, update the `docker-compose.yml` files.

```yaml
services:
  v2ray:
    image: ghcr.io/getimages/v2ray:latest
    # ...
```

* GitHub:
  * Image: ```ghcr.io/getimages/v2ray:latest```
  * URL: https://github.com/orgs/getimages/packages/container/package/v2ray
  * Digest: `sha256:978c67f3dba2afb01b710620f8bc0392b36729facad466b90a49f3d7f30404be`
* Docker Hub:
  * Image: ```v2ray/official:latest```
  * URL: https://hub.docker.com/r/v2ray/official/tags
  * Digest: `sha256:978c67f3dba2afb01b710620f8bc0392b36729facad466b90a49f3d7f30404be`
  
Both images are the same.
There is also a comparison [here](https://github.com/miladrahimi/v2ray-docker-compose/issues/18) by
[@ohmydevops](https://github.com/ohmydevops).

## P.S.

This repository is kind of forked from [v2ray-config-examples](https://github.com/xesina/v2ray-config-examples).
Thanks to [@xesina](https://github.com/xesina) and other contributors.
