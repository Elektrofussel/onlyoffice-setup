#!/bin/bash

set -e

echo "🚀 OnlyOffice Setup - Proxmox LXC"

read -p "Container Name (z. B. OnlyOfficeServer): " CT_NAME
read -p "Template Storage (z. B. local-lvm): " TEMPLATE_STORAGE
read -p "Template Path (z. B. vztmpl/debian-12-standard_12.7-1_amd64.tar.zst): " TEMPLATE_PATH

read -p "IPv4 Modus (static/dhcp): " IPV4_MODE
if [[ "$IPV4_MODE" == "static" ]]; then
    read -p "IPv4 Adresse (z. B. 192.168.2.2/24): " IPV4_ADDR
    read -p "IPv4 Gateway (z. B. 192.168.2.1): " IPV4_GW
else
    IPV4_ADDR=""
    IPV4_GW=""
fi

read -p "IPv6 Modus (static/dhcp/none): " IPV6_MODE
if [[ "$IPV6_MODE" == "static" ]]; then
    read -p "IPv6 Adresse (optional): " IPV6_ADDR
    read -p "IPv6 Gateway (optional): " IPV6_GW
else
    IPV6_ADDR=""
    IPV6_GW=""
fi

if [[ -z "$CT_NAME" || -z "$TEMPLATE_STORAGE" || -z "$TEMPLATE_PATH" ]]; then
    echo "❌ Fehler: Name, Template Storage und Template Path sind Pflicht!"
    exit 1
fi

echo "📦 Lösche bestehenden Container (falls vorhanden)..."
pct stop $CT_NAME || true
pct destroy $CT_NAME || true

echo "📦 Erstelle neuen Container: $CT_NAME"
pct create 999 "/mnt/pve/${TEMPLATE_STORAGE}/template/cache/${TEMPLATE_PATH}"     --arch amd64     --cores 2     --memory 4096     --swap 1024     --unprivileged 1     --net0 "name=eth0,bridge=vmbr0,ip${IPV4_MODE}=${IPV4_ADDR},gw=${IPV4_GW},ip6=${IPV6_MODE},ip6addr=${IPV6_ADDR},ip6gw=${IPV6_GW}"     --hostname "onlyoffice"     --storage "local-lvm"     --features "nesting=1"     --ostype "debian"

pct start 999
sleep 10

echo "🌍 Setze Locale im Container"
pct exec 999 -- bash -c "
apt-get update
apt-get install -y locales
echo 'en_US.UTF-8 UTF-8' > /etc/locale.gen
locale-gen
update-locale LANG=en_US.UTF-8
echo 'export LANG=en_US.UTF-8' >> /etc/profile
echo 'export LANG=en_US.UTF-8' >> /root/.bashrc
"

echo "💾 Installiere OnlyOffice Document Server"
pct exec 999 -- bash -c "
export LANG=en_US.UTF-8
apt-get update
apt-get install -y gnupg2 wget apt-transport-https ca-certificates

wget -qO - https://download.onlyoffice.com/repo/onlyoffice.key | gpg --dearmor > /usr/share/keyrings/onlyoffice-keyring.gpg
echo 'deb [signed-by=/usr/share/keyrings/onlyoffice-keyring.gpg] https://download.onlyoffice.com/repo/debian squeeze main' > /etc/apt/sources.list.d/onlyoffice.list

apt-get update
apt-get install -y onlyoffice-documentserver
"

echo "✅ Installation abgeschlossen!"
