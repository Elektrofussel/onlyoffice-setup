#!/bin/bash

set -e

# Parameter einlesen
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --ct-name) CT_NAME="$2"; shift ;;
        --ipv4-mode) IPV4_MODE="$2"; shift ;;
        --ipv4-addr) IPV4_ADDR="$2"; shift ;;
        --ipv4-gw) IPV4_GW="$2"; shift ;;
        --ipv6-mode) IPV6_MODE="$2"; shift ;;
        --ipv6-addr) IPV6_ADDR="$2"; shift ;;
        --ipv6-gw) IPV6_GW="$2"; shift ;;
        --template-storage) TEMPLATE_STORAGE="$2"; shift ;;
        --template-path) TEMPLATE_PATH="$2"; shift ;;
        *) echo "Unbekannter Parameter: $1"; exit 1 ;;
    esac
    shift
done

# Validierung
if [ -z "$CT_NAME" ] || [ -z "$TEMPLATE_STORAGE" ] || [ -z "$TEMPLATE_PATH" ]; then
    echo "Fehler: Name, Template Storage und Template Path sind Pflicht!"
    exit 1
fi

# Netzwerkkonfiguration
NET_CONFIG=""
if [ "$IPV4_MODE" = "dhcp" ]; then
    NET_CONFIG="ip=dhcp"
else
    NET_CONFIG="ip=$IPV4_ADDR,gw=$IPV4_GW"
fi

if [ "$IPV6_MODE" = "dhcp" ]; then
    NET_CONFIG="$NET_CONFIG,ip6=dhcp"
elif [ "$IPV6_MODE" = "static" ]; then
    NET_CONFIG="$NET_CONFIG,ip6=$IPV6_ADDR,gw6=$IPV6_GW"
fi

# Container erstellen
pct create 206 $TEMPLATE_STORAGE:$TEMPLATE_PATH \
    -hostname $CT_NAME \
    -memory 4096 \
    -swap 512 \
    -cores 2 \
    -net0 name=eth0,bridge=vmbr0,$NET_CONFIG \
    -storage local-lvm \
    -features nesting=1 \
    -unprivileged 1

# Systemd-Fix in Config schreiben
cat <<EOF >> /etc/pve/lxc/206.conf
lxc.apparmor.profile: unconfined
lxc.cgroup.devices.allow: a
lxc.cap.drop:
EOF

# Rest (Installation etc.) bleibt wie gehabt - hier kann dein ursprünglicher Code weiterlaufen
echo "Container erstellt mit Hostname $CT_NAME"
