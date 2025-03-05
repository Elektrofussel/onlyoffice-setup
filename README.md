# OnlyOffice LXC Setup für Proxmox

Dieses Skript erstellt einen unprivilegierten Debian 12 LXC-Container auf Proxmox und installiert OnlyOffice Document Server.

## 📥 Installation

```bash
wget -4 -qO setup_onlyoffice.sh https://raw.githubusercontent.com/Elektrofussel/onlyoffice-setup/main/setup_onlyoffice.sh && chmod +x setup_onlyoffice.sh && ./setup_onlyoffice.sh
```

## Parameter die abgefragt werden:

- Container ID (z. B. 206)
- Container Name (z. B. OnlyOfficeServer)
- Template Storage (z. B. MediumPlate)
- Template Path (z. B. vztmpl/debian-12-standard_12.7-1_amd64.tar.zst)
- IPv4 (static oder dhcp)
- IPv6 (static, dhcp oder none)

## Voraussetzungen

- Proxmox VE 7/8
- Debian 12 Template vorhanden im Storage

## 📄 Hinweis

Nach der Installation füge die Container-IP und den Namen in die Nextcloud `/etc/hosts` ein, z. B.:
```
192.168.2.206 OnlyOfficeServer
```
