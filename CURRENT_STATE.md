# SANDRA — Current State

Aggiornato: 2026-07-21T18:15:03Z

## Struttura canonica

Lo scheletro top-level approvato e presente è:

- cli
- core
- config
- decision
- policy
- execute
- provider
- verify
- remember
- knowledge
- habitat
- report
- docker
- artifacts

La struttura è congelata dalla Costituzione:
`/opt/sandra/knowledge/docs/constitution/CANONICAL-SKELETON.md`

## Componenti operativi

### Core
- `/opt/sandra/core/core.sh`
- versione `1.1.1`
- obbligatorio in ogni Bash SANDRA tramite `source`
- source ripetuto preserva lo stato del Run Bundle attivo

### Knowledge
- `/opt/sandra/knowledge/knowledge.sh`
- repository Git attivo
- obbligatorio in ogni Bash SANDRA tramite `source`

### Execute
- `/opt/sandra/execute/execute.sh`
- operativo
- non decisionale

### PVE
- `/opt/sandra/provider/pve/provider.sh`
- versione `1.7.0`
- connessione SSH certificata
- versione, nodi, risorse, VM, container e storage osservabili
- start safe-path certificato

### Policy PVE
- `/opt/sandra/policy/pve-policy.json`
- `/opt/sandra/policy/pve_validate.py`
- operativa

### Habitat PVE
- `/opt/sandra/habitat/hypervisor/proxmoxve/`
- `habitat.json` presente

## PBS

- host `192.168.1.194`
- utente SSH `root`
- chiave `/root/.ssh/sandra_pbs_ed25519`
- accesso SSH senza password certificato
- `proxmox-backup-manager` certificato
- audit capability read-only completato
- versione osservata: `proxmox-backup-server 4.2.3-1 running version: 4.2.2`
- datastore, garbage collection, verify job, prune job, sync job, remote, ACL e utenti osservabili in JSON
- provider PBS `/opt/sandra/provider/pbs/provider.sh`
- versione provider `1.0.0`
- provider PBS read-only operativo e certificato
- sorgente versionata in `src/providers/pbs/`

## Windows

- runtime locale `/opt/sandra/provider/windows/.venv`
- Python `3.13.7`
- PyPSRP `0.9.1`
- ambiente virtuale isolato e certificato
- connessioni WinRM non ancora certificate
- provider Windows non ancora implementato

## Componenti non ancora certificati

- cli
- config
- decision
- verify
- remember
- report
- docker

## Residuo osservato

`/opt/sandra/docs` è ancora presente ma non appartiene allo scheletro costituzionale.
Non viene modificata da questo aggiornamento.
