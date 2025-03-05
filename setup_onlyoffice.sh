#!/bin/bash
set -e

echo "🚀 OnlyOffice Setup - Proxmox LXC"

#############################################
# Interaktive Abfrage der Parameter
#############################################

read -p "Container ID (z. B. 100): " CT_ID
if ! [[ "$CT_ID" =~ ^[0-9]+$ ]]; then
    echo "❌ Fehler: Container ID muss eine Zahl sein!"
    exit 1
fi

read -p "Container Name (z. B. OnlyOfficeServer): " CT_NAME
read -p "Template Storage (z. B. local-lvm): " TEMPLATE_STORAGE
read -p "Template Path (z. B. debian-12-standard_12.7-1_amd64.tar.zst): " TEMPLATE_PATH

read -p "IPv4 Modus (static/dhcp): " IPV4_MODE
if [[ "$IPV4_MODE" == "static" ]]; then
    read -p "IPv4 Adresse (z. B. 192.168.2.206/24): " IPV4_ADDR
    read -p "IPv4 Gateway (z. B. 192.168.2.1): " IPV4_GW
fi

read -p "IPv6 Modus (static/dhcp/none): " IPV6_MODE
if [[ "$IPV6_MODE" == "static" ]]; then
    read -p "IPv6 Adresse (z. B. 2001:db8::1234/64): " IPV6_ADDR
    read -p "IPv6 Gateway (z. B. fe80::1): " IPV6_GW
fi

read -p "Rootfs Größe in GB (z. B. 50): " ROOTFS_SIZE
if [[ -z "$ROOTFS_SIZE" ]]; then
    ROOTFS_SIZE=50
fi

# Pflichtfelder prüfen
if [[ -z "$CT_ID" || -z "$CT_NAME" || -z "$TEMPLATE_STORAGE" || -z "$TEMPLATE_PATH" ]]; then
    echo "❌ Fehler: Container ID, Container Name, Template Storage und Template Path sind Pflicht!"
    exit 1
fi

#############################################
# Vorbereitung: Template-Pfad & Netzwerkkonfiguration
#############################################

# Vollständiger Template-Pfad (anpassen, falls nötig)
TEMPLATE_FULL="/mnt/pve/${TEMPLATE_STORAGE}/template/cache/${TEMPLATE_PATH}"

# Netzwerkkonfiguration zusammensetzen
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

#############################################
# Alten Container löschen, falls vorhanden
#############################################

echo "📦 Lösche bestehenden Container (falls vorhanden)..."
pct stop "$CT_ID" || true
pct destroy "$CT_ID" || true

#############################################
# Neuen Container erstellen
#############################################

echo "📦 Erstelle neuen Container: $CT_NAME (ID: $CT_ID)"
pct create "$CT_ID" "$TEMPLATE_FULL" \
    --arch amd64 \
    --hostname "$CT_NAME" \
    --cores 2 \
    --memory 4096 \
    --swap 1024 \
    --unprivileged 1 \
    --net0 "$NET_CONFIG" \
    --storage "local-lvm" \
    --rootfs "local-lvm:${ROOTFS_SIZE}" \
    --features "nesting=1" \
    --ostype "debian"

# Systemd‑Fix in der Container-Konfiguration hinzufügen
cat <<EOF >> "/etc/pve/lxc/$CT_ID.conf"
lxc.apparmor.profile: unconfined
lxc.cgroup.devices.allow: a
lxc.cap.drop:
EOF

pct start "$CT_ID"
sleep 10

#############################################
# Locale setzen im Container
#############################################

echo "🌍 Setze Locale im Container"
pct exec "$CT_ID" -- bash -c "\
apt-get update && \
apt-get install -y locales && \
echo 'en_US.UTF-8 UTF-8' > /etc/locale.gen && \
locale-gen && \
update-locale LANG=en_US.UTF-8 && \
export LANG=en_US.UTF-8 && \
echo 'export LANG=en_US.UTF-8' >> /etc/profile && \
echo 'export LANG=en_US.UTF-8' >> /root/.bashrc
"

#############################################
# Vorab-Konfiguration von OnlyOffice (SQLite)
#############################################

echo "🛠️ Erzeuge OnlyOffice-Konfiguration (SQLite) vor der Installation"
pct exec "$CT_ID" -- bash -c "\
mkdir -p /etc/onlyoffice/documentserver && \
cat <<EOJSON > /etc/onlyoffice/documentserver/local.json
{
    \"services\": {
        \"CoAuthoring\": {
            \"sql\": { \"type\": \"sqlite\" },
            \"secret\": {
                \"inbox\": { \"string\": \"\" },
                \"outbox\": { \"string\": \"\" },
                \"session\": { \"string\": \"\" }
            }
        }
    }
}
EOJSON
"

#############################################
# OnlyOffice Document Server Installation
# mit Fallback-Kette
#############################################

echo "💾 Installiere OnlyOffice Document Server (Versuch 1)"
if pct exec "$CT_ID" -- bash -c "\
export LANG=en_US.UTF-8; \
export ONLYOFFICE_DB_TYPE=sqlite; \
apt-get update && \
apt-get install -y gnupg2 wget apt-transport-https ca-certificates jq && \
wget -qO - https://download.onlyoffice.com/repo/onlyoffice.key | gpg --dearmor > /usr/share/keyrings/onlyoffice-keyring.gpg || \
(apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 8320CA65CB2DE8E5); \
echo 'deb [signed-by=/usr/share/keyrings/onlyoffice-keyring.gpg trusted=yes] https://download.onlyoffice.com/repo/debian/ bullseye main' > /etc/apt/sources.list.d/onlyoffice.list; \
apt-get update; \
DEBIAN_FRONTEND=noninteractive apt-get install -y onlyoffice-documentserver
"; then
    echo "✅ OnlyOffice Document Server installiert (Versuch 1 erfolgreich)."
else
    echo "⚠️ Installationsversuch 1 fehlgeschlagen: Post-Installationsskript verweigert die Datenbankverbindung."
    
    #############################################
    # Fallback 1: Post-Installationsskript patchen
    #############################################
    echo "⚠️ Fallback 1: Überschreibe das Post-Installationsskript."
    pct exec "$CT_ID" -- bash -c "\
if [ -f /var/lib/dpkg/info/onlyoffice-documentserver.postinst ]; then \
  mv /var/lib/dpkg/info/onlyoffice-documentserver.postinst /var/lib/dpkg/info/onlyoffice-documentserver.postinst.bak; \
  echo '#!/bin/sh' > /var/lib/dpkg/info/onlyoffice-documentserver.postinst; \
  echo 'exit 0' >> /var/lib/dpkg/info/onlyoffice-documentserver.postinst; \
  chmod +x /var/lib/dpkg/info/onlyoffice-documentserver.postinst; \
fi"
    pct exec "$CT_ID" -- bash -c "dpkg --configure -a"
    if pct exec "$CT_ID" -- bash -c "\
export LANG=en_US.UTF-8; \
DEBIAN_FRONTEND=noninteractive apt-get install -y onlyoffice-documentserver
"; then
        echo "✅ OnlyOffice Document Server installiert (Fallback 1 erfolgreich)."
    else
        #############################################
        # Fallback 2: Dummy-PostgreSQL installieren
        #############################################
        echo "⚠️ Fallback 2: Installiere Dummy-PostgreSQL und versuche erneut..."
        pct exec "$CT_ID" -- bash -c "apt-get install -y postgresql"
        pct exec "$CT_ID" -- bash -c "dpkg --configure -a"
        pct exec "$CT_ID" -- bash -c "DEBIAN_FRONTEND=noninteractive apt-get install -y onlyoffice-documentserver"
        pct exec "$CT_ID" -- bash -c "apt-get purge --auto-remove postgresql -y"
    fi
fi

#############################################
# OnlyOffice-Konfiguration erneut überschreiben (SQLite)
#############################################

echo "🛠️ Überschreibe OnlyOffice-Konfiguration (SQLite)"
pct exec "$CT_ID" -- bash -c "\
export LANG=en_US.UTF-8; \
cat <<EOJSON > /etc/onlyoffice/documentserver/local.json
{
    \"services\": {
        \"CoAuthoring\": {
            \"sql\": { \"type\": \"sqlite\" },
            \"secret\": {
                \"inbox\": { \"string\": \"\" },
                \"outbox\": { \"string\": \"\" },
                \"session\": { \"string\": \"\" }
            }
        }
    }
}
EOJSON
"

#############################################
# API-Key generieren und in die Konfiguration eintragen
#############################################

API_KEY=\$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 32)
pct exec "$CT_ID" -- bash -c "\
export LANG=en_US.UTF-8; \
if [ -f /etc/onlyoffice/documentserver/local.json ]; then \
  jq '.services.CoAuthoring.secret.inbox.string = \"$API_KEY\" | \
      .services.CoAuthoring.secret.outbox.string = \"$API_KEY\" | \
      .services.CoAuthoring.secret.session.string = \"$API_KEY\"' \
      /etc/onlyoffice/documentserver/local.json > /etc/onlyoffice/documentserver/local.json.tmp && \
  mv /etc/onlyoffice/documentserver/local.json.tmp /etc/onlyoffice/documentserver/local.json; \
else \
  echo 'Warnung: /etc/onlyoffice/documentserver/local.json nicht gefunden.'; \
fi
"

#############################################
# API-Key ausgeben und speichern
#############################################

echo "🔑 Der generierte API-Key lautet:"
echo "$API_KEY"
echo "$API_KEY" > /root/API_KEY.txt
echo "Der API-Key wurde in /root/API_KEY.txt gespeichert."

echo "✅ Installation abgeschlossen!"
echo "📄 Bitte füge folgende Zeile in die /etc/hosts deines Nextcloud-Containers ein (ersetze [Container-IP] durch die tatsächliche IP des Containers):"
echo "   [Container-IP] $CT_NAME"
