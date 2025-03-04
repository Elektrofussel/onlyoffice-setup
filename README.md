# OnlyOffice LXC Setup Script

Dieses Skript erstellt einen unprivilegierten LXC-Container auf Proxmox VE und installiert darin den OnlyOffice DocumentServer. Die Konfiguration erfolgt direkt über Parameter, sodass das Skript flexibel für verschiedene Setups verwendet werden kann.

## Features

✅ Unprivilegierter LXC (sicherer Betrieb)  
✅ Direct-Install mit Debian 12 Template  
✅ Flexible Netzwerk-Konfiguration (IPv4/IPv6, DHCP oder statisch)  
✅ Firewall-Regel direkt integriert (nur Nextcloud darf zugreifen)  
✅ Vollautomatische Installation ohne Interaktivität  
✅ Unterstützung für SQLite als Datenbank (kein PostgreSQL nötig)

---

## Parameter

| Parameter | Beschreibung | Beispiel |
|---|---|---|
| `--ct-name` | Name des Containers (Hostname) | `OnlyOfficeServer` |
| `--ipv4-mode` | `static` oder `dhcp` | `static` |
| `--ipv4-addr` | IPv4-Adresse inkl. Subnetz | `192.168.2.206/24` |
| `--ipv4-gw` | IPv4-Gateway | `192.168.2.1` |
| `--ipv6-mode` | `static`, `dhcp` oder `none` | `dhcp` |
| `--ipv6-addr` | IPv6-Adresse inkl. Subnetz (nur bei static) | `fd00::206/64` |
| `--ipv6-gw` | IPv6-Gateway (nur bei static) | `fd00::1` |
| `--template-storage` | Name des Storage mit Template | `MediumPlate` |
| `--template-path` | Pfad zum Template (falls vorhanden) | `vztmpl/debian-12-standard_12.7-1_amd64.tar.zst` |

---

## Beispielaufruf

```bash
bash setup_onlyoffice.sh \
    --ct-name "OnlyOfficeServer" \
    --ipv4-mode "static" \
    --ipv4-addr "192.168.2.206/24" \
    --ipv4-gw "192.168.2.1" \
    --ipv6-mode "dhcp" \
    --template-storage "MediumPlate" \
    --template-path "vztmpl/debian-12-standard_12.7-1_amd64.tar.zst"
```

---

## Nutzung

1. Skript herunterladen oder aus dem Repo klonen.
2. Parameter anpassen (siehe Tabelle).
3. Skript ausführen.
4. In Nextcloud die `/etc/hosts` anpassen und OnlyOffice-App konfigurieren.

---

## Voraussetzungen

- Proxmox VE 7/8
- Debian 12 Template im angegebenen Storage
- Nextcloud mit OnlyOffice App installiert
- IP-Konzept für den Container vorhanden

---

## Hinweise

- SQLite wird als Datenbank genutzt, kein externer DB-Server nötig.
- Der Container wird unprivilegiert erstellt.
- Systemd-Fix für LXC ist integriert.


Kompett erstellt mit ChatGPT
