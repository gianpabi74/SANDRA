# Next Task

> GENERATED FILE — DO NOT EDIT MANUALLY  
> Source: `STATE.json`

## RB-000062 — Risoluzione deterministica oggetto-servizio Linux

### Tipo

`remote_read_only_resolution`

### Target

- PBS
- TRANSMISSION
- PIHOLE
- PIHOLE2
- PLEX
- NAVIDROME
- SERVARR
- PASSBOLT
- NGINX

### Target esclusi

- PVE
- SANDRA
- Windows systems

### Obiettivi

- associare deterministicamente ogni oggetto applicativo alla relativa unita systemd
- usare il nome oggetto, il profilo e l'inventario systemd certificato
- produrre esclusivamente RESOLVED, NOT_FOUND o AMBIGUOUS
- proseguire esclusivamente quando tutti gli oggetti applicativi risultano RESOLVED
- registrare la mappa oggetto-servizio come evidenza machine-readable

### Divieti

- nessuna approvazione manuale dei servizi
- nessuna modifica ai target
- nessun systemctl start
- nessun systemctl stop
- nessun systemctl restart
- nessun systemctl enable
- nessun systemctl disable
- nessuna modifica ai profili
- nessuna implementazione LinuxService
- nessuna scelta in caso di ambiguita

### Gate successivo

Solo dopo il completamento deterministico del gate corrente:

`RB-000063`
