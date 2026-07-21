# Next Task

## Provider PBS

Creare il provider PBS nel percorso canonico:

`/opt/sandra/provider/pbs/`

Prerequisiti certificati:

- host `192.168.1.194`
- utente SSH `root`
- chiave `/root/.ssh/sandra_pbs_ed25519`
- CLI locale `proxmox-backup-manager`

Vincoli:

- nessuna nuova directory top-level
- nessuna modifica a Execute non necessaria
- uso della documentazione ufficiale PBS
- capability verificate prima dell implementazione
- audit capability read-only completato con RB-000031
- implementazione limitata alle capability certificate
- ogni Bash importa Core e Knowledge
- ogni modifica aggiorna Knowledge, journal, stato e roadmap pertinenti
