# SANDRA — Current State

Aggiornato: 2026-07-21T22:14:59Z

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
- WinRM certificato su WINSRV01 (`192.168.1.251`)
- WinRM certificato su WINSRV02 (`192.168.1.203`)
- WinRM certificato su SERVICESRV (`192.168.1.204`)
- autenticazione NTLM e cifratura messaggio obbligatoria
- inventario iniziale di sistema operativo, dominio, ruoli e feature acquisito
- audit approfondito read-only completato su WINSRV01, WINSRV02 e SERVICESRV
- evidenze acquisite per AD DS, replica, DNS, DHCP, IIS, AD CS, servizi e condivisioni
- contratto Windows Microsoft DSC Get/Test/Set approvato
- SPEC-000023 presente
- profili Desired State Windows certificati
- provider Windows `/opt/sandra/provider/windows/provider.sh`
- versione provider `1.0.0`
- operazione Microsoft DSC Get certificata
- operazione Microsoft DSC Test certificata
- WINSRV01 non conforme: modulo DhcpServer presente ma non importabile
- WINSRV02 non conforme: modulo DhcpServer presente ma non importabile
- SERVICESRV conforme al Desired State corrente
- operazione Microsoft DSC Set non ancora implementata

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

## RB-000045A — Provider Windows 1.1.0

- refactoring Base64 completato;
- `get.py` e `test.py` separati dal provider Bash;
- locale PyPSRP `it-IT` certificata;
- `ProviderVersion` coerente a `1.1.0` in Get e Test;
- la non conformità è registrata come risultato di Test e non come errore del provider;
- modifiche alle VM Windows: nessuna.
- WINSRV01: Desired State `FALSE`, delta `1`
- WINSRV02: Desired State `FALSE`, delta `1`
- SERVICESRV: Desired State `FALSE`, delta `1`
## RB-000046 — Baseline Provider Windows

- baseline provider Windows certificata;
- refactoring confermato;
- runtime/source coerenti;
- nessun codice Base64 residuo;
- prossimo RB: introduzione della selezione deterministica della cultura per modulo Microsoft (DhcpServer → it-IT, SmbShare → en-US).

## RB-000047R — Locale deterministica moduli Windows

- provider Windows `1.2.0` certificato;
- locale predefinita: `it-IT`;
- override dichiarativo esatto: `SMBShare -> en-US`;
- `DhcpServer` importabile in `it-IT`;
- `SMBShare` importabile in `en-US`;
- WINSRV01 conforme;
- WINSRV02 conforme;
- SERVICESRV conforme;
- delta complessivo: `0`;
- nessuna modifica alle VM Windows;
- root cause RB-000047: differenza maiuscole/minuscole tra `SmbShare` e `SMBShare`.
