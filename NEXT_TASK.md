# Next Task

> GENERATED FILE — DO NOT EDIT MANUALLY  
> Source: `STATE.json`

## RB-000062 — Baseline certificata dei servizi Linux

### Tipo

`remote_read_only_audit`

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

- raccogliere le unita systemd in formato strutturato
- acquisire Name, Description, LoadState, ActiveState, SubState, UnitFileState e FragmentPath
- classificare servizi applicativi, infrastrutturali e del sistema operativo
- produrre un inventario JSON per host
- proporre esclusivamente i servizi candidati alla gestione
- attendere approvazione umana della baseline

### Divieti

- nessuna modifica ai target
- nessun systemctl start
- nessun systemctl stop
- nessun systemctl enable
- nessun systemctl disable
- nessuna modifica ai profili
- nessuna implementazione LinuxService

### Gate successivo

Solo dopo approvazione:

`RB-000063`
