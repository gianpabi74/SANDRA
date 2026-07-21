# SPEC-000016 — Proxmox Operational Policy

## Stato

Certified PASS.

## Percorso canonico

`/opt/sandra/policy/proxmox-policy.json`

## Provider richiesto

Proxmox provider `1.6.0` o successivo.

## Recupero automatico

Ogni VM QEMU o container LXC osservato in stato `stopped` deve essere
avviato automaticamente.

Sono consentiti al massimo tre tentativi.

Dopo il terzo tentativo fallito:

- lo stato diventa `CRITICAL`;
- non vengono eseguiti ulteriori tentativi automatici;
- è richiesto intervento umano.

## Gruppi ridondanti

### Active Directory

- `qemu/101` — WINSRV01
- `qemu/112` — WINSRV02

Almeno un membro deve rimanere online.

Stop, shutdown e reboot simultanei sono vietati.

### DNS Resolver

- `lxc/100` — PIHOLE
- `qemu/113` — PIHOLE2

Almeno un membro deve rimanere online.

Stop, shutdown e reboot simultanei sono vietati.

## Protezioni runtime

### PBS

`qemu/104`

Stop, shutdown e reboot sono vietati quando:

`pbs_backup_running = true`

La schedulazione delle attività di backup inizia indicativamente alle
ore 02:00, ma il blocco operativo dipende dallo stato reale del backup.

### PLEX

`lxc/102`

Stop, shutdown e reboot sono vietati quando:

`plex_streaming_active = true`

### NAVIDROME

`lxc/103`

Stop, shutdown e reboot sono vietati quando:

`navidrome_streaming_active = true`

## Policy predefinita

Gli altri oggetti non hanno limitazioni aggiuntive.

Delete e destroy restano esclusivamente manuali.
