#!/bin/bash
set -e

echo "🚀 OnlyOffice Setup - Proxmox LXC"

# Userabfragen
read -p "Container ID (z. B. 101): " CT_ID
if ! [[ "$CT_ID" =~ ^[0-9]+$ ]]; then
    echo "❌ Fehler: Container ID muss eine Zahl sein!"
    exit 1
fi

read -p "Container Name (z. B. OnlyOfficeServer): " CT_NAME
read -p "Template Storage (z. B. local-lvm): " TEMPLATE_STORAGE
read -p "Template Path (z. B. vztmpl/debian-12-standard_12.7-1_amd64.tar.zst): " TEMPLATE_PATH

read -p "IPv4 Modus (static/dhcp): " IPV4_MODE
if [[ "$IPV4_MODE" == "static" ]]; then
    read -p "IPv4 Adresse (z. B. 192.168.2.2/24): " IPV4_ADDR
    read -p "IPv4 Gateway (z. B. 192.168.2.1): " IPV4_GW
fi

read -p "IPv6 Modus (static/dhcp/none): " IPV6_MODE
if [[ "$IPV6_MODE" == "static" ]]; then
    read -p "IPv6 Adresse (z. B. 2001:db8::1234/64): " IPV6_ADDR
    read -p "IPv6 Gateway (z. B. fe80::1): " IPV6_GW
fi

if [[ -z "$CT_ID" || -z "$CT_NAME" || -z "$TEMPLATE_STORAGE" || -z "$TEMPLATE_PATH" ]]; then
    echo "❌ Fehler: Container ID, Container Name, Template Storage und Template Path sind Pflicht!"
    exit 1
fi

TEMPLATE_FULL="/mnt/pve/${TEMPLATE_STORAGE}/template/cache/${TEMPLATE_PATH}"

NET_CONFIG="name=eth0,bridge=vmbr0"
if [[ "$IPV4_MODE" == "static" ]]; then
    NET_CONFIG="$NET_CONFIG,ip=$IPV4_ADDR,gw=$IPV4_GW"
else
    NET_CONFIG="$NET_CONFIG,ip=dhcp"
fi

if [[ "$IPV6_MODE" == "static" ]]; then
    NET_CONFIG="$NET_CONFIG,ip6=$IPV6_ADDR,gw6=$IPV6_GW"
elif [[ "$IPV6_MODE" == "dhcp" ]]; then
    NET_CONFIG="$NET_CONFIG,ip6=dhcp"
fi

echo "📦 Lösche bestehenden Container (falls vorhanden)..."
pct stop $CT_ID || true
pct destroy $CT_ID || true

echo "📦 Erstelle neuen Container: $CT_NAME (ID: $CT_ID)"
pct create $CT_ID "$TEMPLATE_FULL"     --arch amd64     --hostname "$CT_NAME"     --cores 2     --memory 4096     --swap 1024     --unprivileged 1     --net0 "$NET_CONFIG"     --storage "local-lvm"     --features "nesting=1"     --ostype "debian"

cat <<EOF >> /etc/pve/lxc/$CT_ID.conf
lxc.apparmor.profile: unconfined
lxc.cgroup.devices.allow: a
lxc.cap.drop:
EOF

pct start $CT_ID
sleep 10

pct exec $CT_ID -- bash -c "apt-get update && apt-get install -y locales && echo 'en_US.UTF-8 UTF-8' > /etc/locale.gen && locale-gen && update-locale LANG=en_US.UTF-8 && export LANG=en_US.UTF-8 && echo 'export LANG=en_US.UTF-8' >> /etc/profile && echo 'export LANG=en_US.UTF-8' >> /root/.bashrc
"

pct exec $CT_ID -- bash -c "export LANG=en_US.UTF-8 && apt-get update && apt-get install -y gnupg2 wget apt-transport-https ca-certificates && wget -qO - https://download.onlyoffice.com/repo/onlyoffice.key | gpg --dearmor > /usr/share/keyrings/onlyoffice-keyring.gpg && echo 'deb [signed-by=/usr/share/keyrings/onlyoffice-keyring.gpg] https://download.onlyoffice.com/repo/debian squeeze main' > /etc/apt/sources.list.d/onlyoffice.list && apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y onlyoffice-documentserver
"

echo "✅ Installation abgeschlossen!"
echo "📄 Bitte füge folgende Zeile in die /etc/hosts deines Nextcloud Containers ein:"
echo "   $IPV4_ADDR $CT_NAME"
