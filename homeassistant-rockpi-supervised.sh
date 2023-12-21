#!/bin/bash

apt update && apt upgrade -y && apt install apparmor cifs-utils curl dbus jq libglib2.0-bin lsb-release network-manager nfs-common systemd-journal-remote systemd-resolved udisks2 wget -y

curl -fsSL get.docker.com | sh

# get latest at https://github.com/home-assistant/os-agent/releases/latest

wget https://github.com/home-assistant/os-agent/releases/download/1.6.0/os-agent_1.6.0_linux_aarch64.deb
dpkg -i os-agent_1.6.0_linux_aarch64.deb

git clone https://github.com/home-assistant/supervised-installer.git
cd supervised-installer
cd homeassistant-supervised




cp /usr/bin/ha /usr/bin/ha.old 
cp /usr/share/hassio/apparmor/hassio-supervisor /usr/share/hassio/apparmor/hassio-supervisor.old 
cp /usr/sbin/hassio-apparmor /usr/sbin/hassio-apparmor.old 
cp /usr/sbin/hassio-supervisor /usr/sbin/hassio-supervisor.old 
cp /etc/systemd/resolved.conf /etc/systemd/resolved.conf.old 
cp /etc/systemd/system/systemd-journal-gatewayd.socket.d/10-hassio-supervisor.conf /etc/systemd/system/systemd-journal-gatewayd.socket.d/10-hassio-supervisor.conf.old 
cp /etc/systemd/system/hassio-apparmor.service /etc/systemd/system/hassio-apparmor.service.old 
cp /etc/systemd/system/hassio-supervisor.service  /etc/systemd/system/hassio-supervisor.service.old 
cp /etc/NetworkManager/NetworkManager.conf /etc/NetworkManager/NetworkManager.conf.old 
cp /etc/docker/daemon.json /etc/docker/daemon.json.old 
cp /etc/network/interfaces /etc/network/interfaces.old

mkdir -p /usr/share/hassio/apparmor
mkdir -p /etc/systemd/system/systemd-journal-gatewayd.socket.d
cp ./usr/bin/ha /usr/bin/ha
cp ./usr/share/hassio/apparmor/hassio-supervisor /usr/share/hassio/apparmor/hassio-supervisor
cp ./usr/sbin/hassio-apparmor /usr/sbin/hassio-apparmor
cp ./usr/sbin/hassio-supervisor /usr/sbin/hassio-supervisor
cp ./etc/systemd/resolved.conf /etc/systemd/resolved.conf
cp ./etc/systemd/system/systemd-journal-gatewayd.socket.d/10-hassio-supervisor.conf /etc/systemd/system/systemd-journal-gatewayd.socket.d/10-hassio-supervisor.conf
cp ./etc/systemd/system/hassio-apparmor.service /etc/systemd/system/hassio-apparmor.service
cp ./etc/systemd/system/hassio-supervisor.service  /etc/systemd/system/hassio-supervisor.service
cp ./etc/NetworkManager/NetworkManager.conf /etc/NetworkManager/NetworkManager.conf
cp ./etc/docker/daemon.json /etc/docker/daemon.json
cp ./etc/network/interfaces /etc/network/interfaces

ARCH=$(uname -m)

BINARY_DOCKER=/usr/bin/docker

DOCKER_REPO="ghcr.io/home-assistant"

SERVICE_DOCKER="docker.service"
SERVICE_NM="NetworkManager.service"

# Read infos from web
URL_CHECK_ONLINE="checkonline.home-assistant.io"
URL_VERSION="https://version.home-assistant.io/stable.json"
HASSIO_VERSION=$(curl -s ${URL_VERSION} | jq -e -r '.supervisor')
URL_APPARMOR_PROFILE="https://version.home-assistant.io/apparmor.txt"
systemctl restart "${SERVICE_NM}"
if [ "$(stat -c %a /etc/systemd/resolved.conf)" != "644" ]; then
    info "Setting permissions of /etc/systemd/resolved.conf"
    chmod 644 /etc/systemd/resolved.conf
fi
systemctl enable systemd-resolved.service> /dev/null 2>&1;
systemctl restart systemd-resolved.service
systemctl stop systemd-journal-gatewayd.socket
systemctl enable systemd-journal-gatewayd.socket> /dev/null 2>&1;
systemctl start systemd-journal-gatewayd.socket
systemctl start nfs-utils.service
systemctl restart "${SERVICE_DOCKER}"
sleep 5
PRIMARY_INTERFACE=$(ip route | awk '/^default/ { print $5; exit }')
IP_ADDRESS=$(ip -4 addr show dev "${PRIMARY_INTERFACE}" | awk '/inet / { sub("/.*", "", $2); print $2 }')
MACHINE="raspberrypi4-64"
HASSIO_DOCKER="${DOCKER_REPO}/aarch64-hassio-supervisor"
PREFIX=${PREFIX:-/usr}
SYSCONFDIR=${SYSCONFDIR:-/etc}
DATA_SHARE=${DATA_SHARE:-$PREFIX/share/hassio}
CONFIG="${SYSCONFDIR}/hassio.json"
cat > "${CONFIG}" <<- EOF
{
    "supervisor": "${HASSIO_DOCKER}",
    "machine": "${MACHINE}",
    "data": "${DATA_SHARE}"
}
EOF
sed -i "s,%%HASSIO_CONFIG%%,${CONFIG},g" "${PREFIX}"/sbin/hassio-supervisor
sed -i -e "s,%%BINARY_DOCKER%%,${BINARY_DOCKER},g" \
       -e "s,%%SERVICE_DOCKER%%,${SERVICE_DOCKER},g" \
       -e "s,%%BINARY_HASSIO%%,${PREFIX}/sbin/hassio-supervisor,g" \
       "${SYSCONFDIR}/systemd/system/hassio-supervisor.service"

chmod a+x "${PREFIX}/sbin/hassio-supervisor"
systemctl enable hassio-supervisor.service > /dev/null 2>&1;
mkdir -p "${DATA_SHARE}/apparmor"
curl -sL ${URL_APPARMOR_PROFILE} > "${DATA_SHARE}/apparmor/hassio-supervisor"
sed -i "s,%%HASSIO_CONFIG%%,${CONFIG},g" "${PREFIX}/sbin/hassio-apparmor"
sed -i -e "s,%%SERVICE_DOCKER%%,${SERVICE_DOCKER},g" \
    -e "s,%%HASSIO_APPARMOR_BINARY%%,${PREFIX}/sbin/hassio-apparmor,g" \
    "${SYSCONFDIR}/systemd/system/hassio-apparmor.service"

chmod a+x "${PREFIX}/sbin/hassio-apparmor"
systemctl enable hassio-apparmor.service > /dev/null 2>&1;
systemctl start hassio-apparmor.service
systemctl start hassio-supervisor.service
chmod a+x "${PREFIX}/bin/ha"

echo "Done. Watch docker PS to fill up 5-10min and https://$IP_ADDRESS:8123 should be accsessible"
