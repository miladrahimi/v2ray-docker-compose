# HTTP & SOCKS Protocols

The HTTP proxy protocol is appropriate for internal usage on the bridge server and port forwarding.
It would be exposed to the 127.0.0.1 IP address without passwords.


The SOCKS5 protocol can be used for internal and external use.
You can set a username and password for that or just remove the authentication.

## On the bridge server

The command below shows how to use the HTTP proxy on the bridge server.

```shell
export {http,https}_proxy="http://127.0.0.1:1110"
export {HTTP,HTTPS}_PROXY="http://127.0.0.1:1110"

# This "curl" should return the upstream IP (not bridge!)
curl ifconfig.io

# The "sudo" command needs the -E parameter to use HTTP/SOCKS proxy and other envs
sudo -E apt install docker

unset {http,https}_proxy
unset {HTTP,HTTPS}_PROXY
```

## On the local devices

You can use the HTTP or SOCKS proxies on your local devices using port forwarding.
The following SSH command makes the HTTP proxy available to the local device and the private network it uses.

```shell
ssh -vNL 1110:0.0.0.0:1110 root@13.13.13.13
# ssh -vNL <LOCAL-HTTP-PORT>:<LOCAL-IP-ADDRESS>:<REMOTE-HTTP-PORT> <USER>@<BRIDGE-IP>

export {http,https}_proxy="http://127.0.0.1:1110"
export {HTTP,HTTPS}_PROXY="http://127.0.0.1:1110"
# ...
```

## In SSH connections

You can add the following line to the `$HOME/.ssh/ssh_config` file to use the HTTP or SOCKS proxies in your SSH connections.

* HTTP: ```ProxyCommand /usr/bin/nc -X connect -x 127.0.0.1:HTTP_PROXY_PORT %h %p```
* SOCKS: ```ProxyCommand /usr/bin/nc -X 5 -x 127.0.0.1:SOCKS_PROXY_PORT %h %p```
