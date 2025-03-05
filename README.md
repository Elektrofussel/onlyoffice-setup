# OnlyOffice LXC Setup für Proxmox

Dieses Skript erstellt einen unprivilegierten Debian 12 LXC-Container auf Proxmox und installiert OnlyOffice Document Server.

## 📥 Installation

```bash
wget -4 -O setup_onlyoffice.sh https://raw.githubusercontent.com/Elektrofussel/onlyoffice-setup/main/setup_onlyoffice.sh && chmod +x setup_onlyoffice.sh && ./setup_onlyoffice.sh
```

## Parameter die abgefragt werden:

- Container ID (z. B. 101)
- Container Name (z. B. OnlyOfficeServer)
- Template Storage (z. B. local-lvm)
- Template Path (z. B. debian-12-standard_12.7-1_amd64.tar.zst)
- IPv4 (static oder dhcp)
- IPv6 (static, dhcp oder none)

## Voraussetzungen

- Proxmox VE 7/8
- Debian 12 Template vorhanden im Storage

## 📄 Hinweis

Nach der Installation füge die Container-IP und den Namen in die Nextcloud `/etc/hosts` ein, z. B.:
```
192.168.2.101 OnlyOfficeServer
```
Außerdem wird der generierte API‑Key der OnlyOffice‑Konfiguration, in der Konsole ausgegeben und in `/root/API_KEY.txt` gespeichert bzw. in dem Speicherort des setup_onlyoffice.sh Skript`s.

## Schluss

Das Skript und die Readme wurden mit OpenAI`s Projekt ChatGPT Model 4o realisiert.
Anregungen, Änderungen, Verbesserungen gern stellen, oder einfach selbst das Projekt ab ändern.
