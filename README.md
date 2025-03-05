# OnlyOffice Setup für Proxmox

Dieses Skript erstellt einen unprivilegierten Debian 12 LXC-Container, setzt die Netzwerkkonfiguration und installiert OnlyOffice Document Server.

## 📥 Installation

```bash
wget -qO setup_onlyoffice.sh https://raw.githubusercontent.com/Elektrofussel/onlyoffice-setup/main/setup_onlyoffice.sh && chmod +x setup_onlyoffice.sh && ./setup_onlyoffice.sh
```

## ⚙️ Ablauf

1. Abfragen von:
   - Container-Name
   - Template Storage & Path
   - IPv4/IPv6 Konfiguration
2. Löschen eines bestehenden Containers (falls vorhanden)
3. Anlegen & Starten des neuen Containers
4. Setzen der Locale im Container
5. Hinzufügen des OnlyOffice Repos
6. Installation des Document Servers

## 📋 Voraussetzungen

- Proxmox 7/8
- Debian 12 Template im angegebenen Storage vorhanden
- Internetzugang für apt & wget

## 📝 Beispiel

```
Container Name: OnlyOfficeServer
Template Storage: MediumPlate
Template Path: vztmpl/debian-12-standard_12.7-1_amd64.tar.zst
IPv4: static 192.168.2.206/24 mit Gateway 192.168.2.1
IPv6: dhcp
```

## Schluss

Das Skript, sowie der Inhalt der Readme wurde durch die ChatGPT 4o von OpenAI erstellt.
Anregungen, Änderungswünsche oder fortsetzen des Projektes ist von mir gewünscht, ansonsten viel Spaß und Erfolg!
