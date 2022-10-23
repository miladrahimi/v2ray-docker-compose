#!/usr/bin/env bash

# v2ray installer
# https://github.com/miladrahimi/v2ray-docker-compose
# with regards to:
#	https://github.com/angristan/wireguard-install

DATA_DIR="$PWD/v2ray-data"

COLOR_PREFIX="\033["
# color code
RED="31"      # error
GREEN="32"    # success
YELLOW="33"   # warning
BLUE="34"     # info
CYAN="36"     # instruction
NORMAL="0"		# reset

colorEcho(){
	echo -e "${COLOR_PREFIX}${1}m${@:2}${COLOR_PREFIX}${NORMAL}m"
}

function isRoot() {
	if [ "${EUID}" -ne 0 ]; then
		echo "You need to run this script as root"
		exit 1
	fi
}

function checkDocker() {
    if ! [[ $(which docker) && $(docker ps) ]]; then
        colorEcho ${RED} "docker is not installed/running"
        exit 1
    elif ! [[ $(which docker-compose) ]]; then
        colorEcho ${RED} "docker-compose is not installed"
        exit 1
    fi

}

function checkOS() {
	# Check OS version
	if [[ -e /etc/debian_version ]]; then
		source /etc/os-release
		OS="${ID}" # debian or ubuntu
		if [[ ${ID} == "debian" || ${ID} == "raspbian" ]]; then
			if [[ ${VERSION_ID} -lt 10 ]]; then
				colorEcho ${RED} "Your version of Debian (${VERSION_ID}) is not supported. Please use Debian 10 Buster or later"
				exit 1
			fi
			OS=debian # overwrite if raspbian
		fi
	elif [[ -e /etc/fedora-release ]]; then
		source /etc/os-release
		OS="${ID}"
	elif [[ -e /etc/arch-release ]]; then
		OS=arch
	else
		colorEcho ${RED} "Looks like you aren't running this installer on a Debian, Ubuntu, Fedora, CentOS, Oracle or Arch Linux system"
		exit 1
	fi
}

function initialCheck() {
	isRoot
	checkDocker
	checkOS
}

function installQuestions() {
	colorEcho ${CYAN} "Welcome to the V2Ray installer!"
	echo "The git repository is available at: https://github.com/miladrahimi/v2ray-docker-compose"
	echo ""
	echo "I need to ask you a few questions before starting the setup."
	echo "You can use the default values if they are correct and just press Enter"
	echo "Ready to use QRCode and URLs for Vmess, Shadowsocks and Vless will be auto-generated after setup is finished"
	echo ""

    # detect server type (bridge or upstream)
    until [[ ${SERVER_TYPE} =~ ^(bridge|upstream)$ ]]; do
		read -rp "Which server is this?(bridge or upstream) " -e -i "upstream" SERVER_TYPE
	done

	# Detect public IPv4 or IPv6 address and pre-fill for the user
	SERVER_PUB_IP=$(ip -4 addr | sed -ne 's|^.* inet \([^/]*\)/.* scope global.*$|\1|p' | awk '{print $1}' | head -1)
	if [[ -z ${SERVER_PUB_IP} ]]; then
		# Detect public IPv6 address
		SERVER_PUB_IP=$(ip -6 addr | sed -ne 's|^.* inet6 \([^/]*\)/.* scope global.*$|\1|p' | head -1)
	fi
	read -rp "Public IPv4 public address(current server): " -e -i "${SERVER_PUB_IP}" SERVER_PUB_IP

	# # Use TLS?
	# until [[ ${USE_TLS} =~ ^(y|n)$ ]]; do
	# 	read -rp "Do you have want to enable TLS? You should have a domain and a valid certificate. (y/n) " -e -i "n" USE_TLS
	# done

	# if [[ $USE_TLS == "y" ]]; then
	# 	until [[ -f ${CERT_PATH} ]]; do
	# 		read -rp "Enter the path to your CERTIFICATE file: " -e -i "$PWD/"  CERT_PATH
	# 	done
	# 	until [[ -f ${KEY_PATH} ]]; do
	# 		read -rp "Enter the path to your KEY file: " -e -i "$PWD/"  KEY_PATH
	# 	done

	# 	CERT_SHA=$(openssl x509 -in $CERT_PATH -pubkey -noout -outform pem | sha256sum)
	# 	KEY_SHA=$(openssl pkey -in $KEY_PATH -pubout -outform pem | sha256sum)
	# 	if [[ $CERT_SHA != $KEY_SHA ]]; then
	# 		colorEcho ${RED} "Certificate/Key pair does not seem to match"
	# 		exit 1
	# 	fi
	# fi

    if [[ $SERVER_TYPE == "bridge" ]]; then
		if [[ $USE_TLS == "y" ]]; then
			colorEcho ${YELLOW} "NOTE: You should create an A or AAAA(in case of IPv6) record for your domain that point to $SERVER_PUB_IP"
		fi

        # Upstream public IP
        until [[ ${UPSTREAM_PUB_IP} =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; do
            read -rp "Upstream server public IPv4: "  UPSTREAM_PUB_IP
        done

		
    elif [[ $SERVER_TYPE == "upstream" ]]; then
		# Bridge public IP (to generate config files)
        until [[ ${BRIDGE_PUB_ADDRESS} =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || [[ ${BRIDGE_PUB_ADDRESS} =~ ^([A-Za-z0-9-]{1,63}\.)+[A-Za-z]{2,6}$  ]]; do
            read -rp "Bridge server's public IPv4 or Domain name: "  BRIDGE_PUB_ADDRESS
        done

    fi

	# # Generate random number within private ports range
	# RANDOM_PORT=$(shuf -i49152-65535 -n1)
	# until [[ ${CLIENT_DNS_2} =~ ^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$ ]]; do

	echo ""
	colorEcho ${GREEN} "That's all. Setting up $SERVER_TYPE server now!"
	# read -n1 -r -p "Press any key to continue..."; echo
}

function installPackages(){
	colorEcho ${GREEN} "Installing needed packages: $1"
    if [[ ${OS} == 'ubuntu' ]] || [[ ${OS} == 'debian' && ${VERSION_ID} -gt 10 ]]; then
        apt-get update
        apt-get install -y $1
    elif [[ ${OS} == 'fedora' ]]; then
        dnf install -y $1
    elif [[ ${OS} == 'centos' ]]; then
        yum -y install epel-release elrepo-release
        if [[ ${VERSION_ID} -eq 7 ]]; then
            yum -y install yum-plugin-elrepo
        fi
        yum -y install $1
    elif [[ ${OS} == 'arch' ]]; then
        pacman -S --needed --noconfirm $1
    fi
}


function pullDockerImage() {
	IMAGE_FILE="/tmp/image.tar"
	if [[ $1 == "v2ray" ]]; then
		IMAGE_ID='0e75a60ce4c9'
		IMAGE_TAR_SHA1SUM='c088e58adf57e10c0631831f1c5676296a169b94'
		PROJECT_DIR='v2ray-upstream-server'
		IMAGE_DOWNLOAD_LINK='https://github.com/UZziell/v2ray-haproxy-docker/releases/download/docker-images/v2fly-v2flycore-v5.1.0-0e75a60ce4c9.tar'
	elif [[ $1 == "haproxy" ]]; then
		IMAGE_ID='6e2d5dace12f'
		IMAGE_TAR_SHA1SUM='6f5422b2d9b97728dfb4091b79d8d4baff0217b6'
		PROJECT_DIR='haproxy-bridge-server'
		IMAGE_DOWNLOAD_LINK='https://github.com/UZziell/v2ray-haproxy-docker/releases/download/docker-images/haproxy-lts-bullseye-6e2d5dace12f.tar'
	fi

	colorEcho ${GREEN} "Pulling $1 image."

	docker images | grep $IMAGE_ID || docker-compose --project-directory $PROJECT_DIR pull
	if [[ $? -ne 0 ]]; then
		[[ -e $IMAGE_FILE ]] || env all_proxy=$all_proxy curl -fSLo $IMAGE_FILE $IMAGE_DOWNLOAD_LINK
		if [[ $(sha1sum $IMAGE_FILE | awk '{print $1}') == $IMAGE_TAR_SHA1SUM ]]; then
			cat $IMAGE_FILE | docker load
		else
			colorEcho ${RED} "Could not pull '$1' image from dockerhub or even github releases)"
			colorEcho ${YELLOW} "If it keeps failing, your server cannot access github.com right now. You can try manually donwling '$IMAGE_DOWNLOAD_LINK' and use 'scp' to copy it to the server,\
then use 'docker image load -i v2fly-v2flycore-v5.1.0-0e75a60ce4c9.tar' OR try some other time"
			rm $IMAGE_FILE
			exit 1
		fi
	fi
}

function generateQR() {
	colorEcho ${BLUE} "########## $1 client configs(URL & QRCode) ##########"
	echo -n $2 | qrencode -t ansiutf8 | tee -a $DATA_DIR/v2ray-defaultUser 
	echo -e "$2\n\n" | tee -a $DATA_DIR/v2ray-defaultUser
	sleep 2
}

function parseConfig() {
	TAG=$1
	PROTOCOL=$(jq -r "(.inbounds[] | select(.tag | match(\"^($TAG)$\")) | .protocol)" $V2RAY_SERVER_CONFIG)
	if [[ $PROTOCOL =~ ^(vmess|vless)$ ]]; then
		PORT=$(jq -r "(.inbounds[] | select(.tag | match(\"^($TAG)$\")) | .port)" $V2RAY_SERVER_CONFIG)
		WS_HOST=$(jq -r "(.inbounds[] | select(.tag | match(\"^($TAG)$\")) | .streamSettings.wsSettings.headers.Host)" $V2RAY_SERVER_CONFIG)
		WS_PATH=$(jq -r "(.inbounds[] | select(.tag | match(\"^($TAG)$\")) | .streamSettings.wsSettings.path)" $V2RAY_SERVER_CONFIG)
		TLS_SNI=$(jq -r "(.inbounds[] | select(.tag | match(\"^($TAG)$\")) | .streamSettings.tlsSettings.serverName)" $V2RAY_SERVER_CONFIG)
		
		if [[ $PROTOCOL == 'vmess' ]]; then
			VMESS_URL=$(echo -n "vmess://$(echo -n "{'add': '$BRIDGE_PUB_ADDRESS', 'aid': '0', 'host': '$WS_HOST', 'id': '$UUID', \
			'net': 'ws', 'path': '$WS_PATH', 'port': '80', 'ps': 'VMESS-Bridged', 'tls': '', 'type': 'none', 'v': '2'}" | base64 -w 0)")
			VMESS_URL_DIRECT=$(echo -n "vmess://$(echo -n "{'add': '$SERVER_PUB_IP', 'aid': '0', 'host': '$WS_HOST', 'id': '$UUID', \
			'net': 'ws', 'path': '$WS_PATH', 'port': '$PORT', 'ps': 'VMESS-Direct', 'tls': '', 'type': 'none', 'v': '2'}" | base64 -w 0)")

			if [[ $TLS_SNI != 'null' ]]; then 
				VMESS_URL=$(echo -n "vmess://$(echo -n "{'add': '$BRIDGE_PUB_ADDRESS', 'aid': '0', 'host': '$WS_HOST', 'id': '$UUID', \
				'net': 'ws', 'path': '$WS_PATH', 'port': '443', 'ps': 'VMESS-Bridged', 'tls': 'tls', 'type': 'none', 'v': '2'}" | base64 -w 0)")
				VMESS_URL_DIRECT=$(echo -n "vmess://$(echo -n "{'add': '$SERVER_PUB_IP', 'aid': '0', 'host': '$WS_HOST', 'id': '$UUID', \
				'net': 'ws', 'path': '$WS_PATH', 'port': '$PORT', 'ps': 'VMESS-Direct', 'tls': 'tls', 'type': 'none', 'v': '2'}" | base64 -w 0)")
			fi
			generateQR "vmess" $VMESS_URL
			generateQR "vmess" $VMESS_URL_DIRECT

		elif [[ $PROTOCOL == 'vless' ]]; then
			VLESS_URL=$(echo -n "vless://${UUID}@${BRIDGE_PUB_ADDRESS}:80?type=ws&path=${WS_PATH}&host=${WS_HOST}#VLESS-Bridged")
			VLESS_URL_DIRECT=$(echo -n "vless://${UUID}@${SERVER_PUB_IP}:${PORT}?type=ws&path=${WS_PATH}&host=${WS_HOST}#VLESS-Direct")

			if [[ $TLS_SNI != 'null' ]]; then 
				VLESS_URL=$(echo -n "vless://${UUID}@${BRIDGE_PUB_ADDRESS}:443?type=ws&security=tls&encryption=none&host=${TLS_SNI}&sni=${TLS_SNI}#VLESS-TLS-Bridged")
				VLESS_URL_DIRECT=$(echo -n "vless://${UUID}@${SERVER_PUB_IP}:${PORT}?type=ws&security=tls&encryption=none&host=${TLS_SNI}&sni=${TLS_SNI}#VLESS-TLS-Direct")
			fi
			generateQR "vless" $VLESS_URL
			generateQR "vless" $VLESS_URL_DIRECT
		fi

	elif [[ $PROTOCOL == 'shadowsocks' ]]; then
		# SHADOWSOCKS READ MORE ABOUT SS URI SCHEME at https://github.com/shadowsocks/shadowsocks-org/wiki/SIP002-URI-Scheme
		SHADOWSOCKS_HOST=$(jq -r "(.inbounds[] | select(.tag | match(\"^($TAG)$\")) | .streamSettings.wsSettings.headers.Host)" $V2RAY_SERVER_CONFIG)
		SHADOWSOCKS_PATH=$(jq -r "(.inbounds[] | select(.tag | match(\"^($TAG)$\")) | .streamSettings.wsSettings.path)" $V2RAY_SERVER_CONFIG)
		SHADOWSOCKS_METHOD=$(jq -r "(.inbounds[] | select(.tag | match(\"^($TAG)$\")) | .settings.method)" $V2RAY_SERVER_CONFIG)
		SHADOWSOCKS_URL=$(echo -n "ss://$(echo -n ${SHADOWSOCKS_METHOD}:${SHADOWSOCKS_PASSWORD} | base64 -w0)@${BRIDGE_PUB_ADDRESS}:80/?plugin=v2ray-plugin;mux=0;mode=websocket;host=${SHADOWSOCKS_HOST};path=${SHADOWSOCKS_PATH}#Shadowsocks")
		generateQR "shadowsocks" $SHADOWSOCKS_URL

	fi

}

function installConfigRun() {
	mkdir -p $DATA_DIR
	V2RAY_CLIENT_CONFIG="./v2ray-docker-client/config/config.json"
	V2RAY_CLIENT_CONFIG_TEMPLATE="./v2ray-docker-client/config/config-template.json"
	V2RAY_SERVER_CONFIG="./v2ray-upstream-server/config/config.json"
	V2RAY_SERVER_CONFIG_TEMPLATE="./v2ray-upstream-server/config/config-template.json"
	V2RAY_SERVER_CERTIFICATE="./v2ray-upstream-server/config/certificate.crt"
	V2RAY_SERVER_CERTIFICATE_KEY="./v2ray-upstream-server/config/certificate.key"
	HAPROXY_CONFIG="./haproxy-bridge-server/haproxy.cfg"
	HAPROXY_CONFIG_TEMPLATE="./haproxy-bridge-server/haproxy-template.cfg"
	HAPROXY_CERTIFICATE="./haproxy-bridge-server/certificate.pem"

	# Run setup questions first
	installQuestions


    if [[ $SERVER_TYPE == "upstream" ]]; then
        # Install needed tools (jq, moreutils, qrencode) and pull docker image
        installPackages "jq moreutils qrencode"
		pullDockerImage "v2ray"

		# TLS
		if [[ $USE_TLS == "y" ]]; then
			cp $CERT_PATH $V2RAY_SERVER_CERTIFICATE 
			cp $KEY_PATH  $V2RAY_SERVER_CERTIFICATE_KEY
		else
            echo "Generating a self-signed certificate for proxy protocols that use TLS as security"
            openssl req -x509 -newkey rsa:2048 -keyout $V2RAY_SERVER_CERTIFICATE_KEY -out $V2RAY_SERVER_CERTIFICATE -sha256 -nodes -days 365 -subj "/CN=$SERVER_PUB_IP" 2> /dev/null
		fi
        # prepare V2Ray config files
        export UUID=$(cat /proc/sys/kernel/random/uuid)
		export SHADOWSOCKS_PASSWORD=$(openssl rand -hex 10)
		# Server
		# Set vmess/vless UUIDs and shadowsocks password
		jq  "(.inbounds[] | select(.protocol | match(\"^(vmess|vless)$\")) | .settings.clients[].id) |= \"$UUID\" | \
			(.inbounds[] | select(.protocol | match(\"^(vmess|vless)$\")) | .settings.clients[].username) |= \"DefaultUser\" | \
			(.inbounds[] | select(.protocol | match(\"^(shadowsocks)$\")) | .settings.password) |= \"$SHADOWSOCKS_PASSWORD\" " $V2RAY_SERVER_CONFIG_TEMPLATE > ${V2RAY_SERVER_CONFIG}
		# Client
		# Set vmess/vless UUIDs, shadowsocks password, and bridge address
		jq  "(.outbounds[] | select(.protocol | match(\"^(vmess|vless)$\")) | .settings.vnext[].users[].id) |= \"$UUID\" | \
			(.outbounds[] | select(.protocol | match(\"^(vmess|vless)$\")) | .settings.vnext[].address) |= \"$BRIDGE_PUB_ADDRESS\" | \
			(.outbounds[] | select(.protocol | match(\"^shadowsocks$\")) | .settings.servers[].address) |= \"$BRIDGE_PUB_ADDRESS\" | \
			(.outbounds[] | select(.protocol | match(\"^shadowsocks$\")) | .settings.servers[].password) |= \"$SHADOWSOCKS_PASSWORD\" " $V2RAY_CLIENT_CONFIG_TEMPLATE > ${V2RAY_CLIENT_CONFIG}

		# Run V2Ray
		docker-compose --project-directory v2ray-upstream-server up -d
		# check if running
		sleep 5 && checkContainerRunning "v2ray_upstream"

		colorEcho ${GREEN} "$SERVER_TYPE server setup finished successfully"
		printf "\n\n"
		read -n1 -r -p "Press any key to show client configs..."; echo

		# Parse server config and generate client QRCode/URL
		for inbound in $(jq -r '(.inbounds[] | .tag )' $V2RAY_SERVER_CONFIG_TEMPLATE); do
			parseConfig $inbound
		done
		colorEcho ${YELLOW} "Saved DefaultUser's configs to '$DATA_DIR/v2ray-defaultUser'  for later use\n"


    elif [[ $SERVER_TYPE == "bridge" ]]; then
        installPackages "jq"
		pullDockerImage "haproxy"

		# Prepare HAProxy config
		VMESS_HOST=$(jq -r '(.inbounds[] | select(.tag | match("^(vmess-ws)$")) | .streamSettings.wsSettings.headers.Host)' $V2RAY_SERVER_CONFIG_TEMPLATE)
		SHADOWSOCKS_HOST=$(jq -r '(.inbounds[] | select(.protocol | match("^(shadowsocks)$")) | .streamSettings.wsSettings.headers.Host)' $V2RAY_SERVER_CONFIG_TEMPLATE)
		VLESS_HOST=$(jq -r '(.inbounds[] | select(.tag | match("^(vless-ws)$")) | .streamSettings.wsSettings.headers.Host)' $V2RAY_SERVER_CONFIG_TEMPLATE)
		VLESS_TLS_SNI=$(jq -r '(.inbounds[] | select(.tag | match("^(vless-tls)$")) | .streamSettings.tlsSettings.serverName)' $V2RAY_SERVER_CONFIG_TEMPLATE)
        export HAPROXY_STATS_PASSWORD=$(openssl rand -hex 20) UPSTREAM_PUB_IP VMESS_HOST SHADOWSOCKS_HOST VLESS_HOST VLESS_TLS_SNI
        envsubst '$HAPROXY_STATS_PASSWORD $UPSTREAM_PUB_IP $VMESS_HOST $SHADOWSOCKS_HOST $VLESS_HOST $VLESS_TLS_SNI' < $HAPROXY_CONFIG_TEMPLATE > $HAPROXY_CONFIG

		# Use entered certificate or generate a self-sign cert for HAProxy
		if [[ $USE_TLS == "y" ]]; then
			cat $CERT_PATH $KEY_PATH > $HAPROXY_CERTIFICATE
		else
            echo "Generating a self-signed certificate for HAProxy stats page"
            openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -sha256 -nodes -days 365 -subj "/CN=$SERVER_PUB_IP" 2> /dev/null
            cat cert.pem key.pem > $HAPROXY_CERTIFICATE && rm -f key.pem cert.pem
		fi
		
		# Run HAProxy
		docker-compose --project-directory haproxy-bridge-server up -d
		sleep 5 && checkContainerRunning "haproxy_bridge"
		colorEcho ${GREEN} "$SERVER_TYPE server setup finished."
		colorEcho ${GREEN} "HAProxy stats page url: https://${SERVER_PUB_IP}:6543/stats"
        colorEcho ${GREEN} "username: uzer\npassword: $HAPROXY_STATS_PASSWORD"
        colorEcho ${YELLOW} "Save this credentials"
        
    fi

	# Save server settings
	cat <<- EOF > $DATA_DIR/params
SERVER_TYPE=${SERVER_TYPE}
SERVER_PUB_IP=${SERVER_PUB_IP}
USE_TLS=${USE_TLS}
UPSTREAM_PUB_IP=${UPSTREAM_PUB_IP}
BRIDGE_PUB_ADDRESS=${BRIDGE_PUB_ADDRESS}
UUID=${UUID}
SHADOWSOCKS_PASSWORD=${SHADOWSOCKS_PASSWORD}
EOF

}

function showClientConfig() {
	cat $DATA_DIR/v2ray-defaultUser
}

function uninstallV2ray() {
	until [[ ${CONFIRM_UNINSTALL} =~ ^(y|n)$ ]]; do
		read -rp "Uninstalling, are you sure? (y/n) " -e -i "n" CONFIRM_UNINSTALL
	done
	if [[ $CONFIRM_UNINSTALL == "y" ]]; then 
		rm -rf $DATA_DIR
		docker-compose --project-directory v2ray-upstream-server down
		colorEcho ${GREEN} "Uninstalled V2Ray from $SERVER_TYPE Server."
	fi

}

function checkContainerRunning() {
	if [[ $1 == 'v2ray_upstream' ]]; then
		PROJECT_DIR='v2ray-upstream-server'
	elif [[ $1 == 'haproxy_bridge' ]]; then
		PROJECT_DIR='haproxy-bridge-server'
	fi

	CID=$(docker ps --filter=name=$1 --filter=status=running -q)
	if [[ -z $CID ]]; then
		colorEcho ${RED} "Container $1 does not exist or is not running. Container logs: "
		docker-compose --project-directory $PROJECT_DIR logs 
		colorEcho ${YELLOW} "If you keep seeing this as startup, try uninstalling the service and install again\n\n"

		# exit unless second parameter is 'noexit'
		[[ $2 == "noexit" ]] || exit 1
	fi
}

function upstreamManageMenu() {
	echo "Welcome to the V2Ray-install!"
	echo "The git repository is available at: https://github.com/miladrahimi/v2ray-docker-compose"
	echo ""
	echo "It looks like V2ray is already installed."
	echo ""
	echo "What do you want to do?"
	echo "   1) Show client configs (QRCode and URLs)"
	echo "   2) Uninstall V2Ray and all configs"
	echo "   3) Exit"
	until [[ ${MENU_OPTION} =~ ^[1-3]$ ]]; do
		read -rp "Select an option [1-3]: " MENU_OPTION
	done
	case "${MENU_OPTION}" in
	1)
		showClientConfig
		;;
	2)
		uninstallV2ray
		;;
	3)
		exit 0
		;;

	# TODO	
		# newClient
		# deleteClient

	esac
}

# Check for root, virt, OS...
initialCheck

# Check if V2Ray is already installed and load params
if [[ -e $DATA_DIR/params ]]; then
	source $DATA_DIR/params
	if [[ $SERVER_TYPE == "upstream" ]]; then
		checkContainerRunning 'v2ray_upstream' 'noexit'
		upstreamManageMenu
	elif [[ $SERVER_TYPE == "bridge" ]]; then
		checkContainerRunning 'haproxy_bridge' 'noexit'
		colorEcho ${GREEN} "HAProxy is running and '$UPSTREAM_PUB_IP' is configured as it's Upstream"
		until [[ ${UNINSTALL_BRIDGE} =~ ^(y|n)$ ]]; do
			read -rp "Do you want to uninstall it?  (y/n) " -e -i "n" UNINSTALL_BRIDGE
		done
		if [[ $UNINSTALL_BRIDGE == "y" ]]; then 
			docker-compose --project-directory haproxy-bridge-server down && rm -rf $DATA_DIR
			colorEcho ${GREEN} "Uninstalled HAProxy from Bridge Server."
		fi
	fi

elif [[ -n $(docker-compose --project-directory haproxy-bridge-server ps -q) ]] || [[ -n $(docker-compose --project-directory v2ray-upstream-server ps -q) ]]; then
	colorEcho ${YELLOW} "It looks like you have executed the script before but the setup was not finished!"
	until [[ ${REMOVE_RUNNING_CONTAINER} =~ ^(y|n)$ ]]; do
		read -rp "Stop and delete running container?(running container is v2ray or haproxy or maybe even both) (y/n) " -e -i "y" REMOVE_RUNNING_CONTAINER
	done
	if [[ $REMOVE_RUNNING_CONTAINER == "y" ]]; then
		docker-compose --project-directory haproxy-bridge-server down
		docker-compose --project-directory v2ray-upstream-server down
		colorEcho ${GREEN} "Stopped and removed. Proceeding..."
		installConfigRun
	else
		colorEcho ${GREEN} "So do it manually and re-execute the install script"
		exit 1
	fi

else 
	installConfigRun
fi
