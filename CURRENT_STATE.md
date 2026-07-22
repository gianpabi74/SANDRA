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

## RB-000048C — Windows provider Set

- provider Windows `1.3.0` certificato;
- funzione `provider_set` installata;
- contratto Set documentato;
- approvazione del delta obbligatoria;
- target e profilo devono coincidere;
- il delta approvato deve coincidere esattamente con il Test;
- delta vuoto: `NO_CHANGES_REQUIRED`;
- risorsa non implementata: `NOT_IMPLEMENTED`;
- approvazione incoerente: rifiutata;
- risorse modificative supportate: nessuna;
- connessioni Windows: nessuna;
- modifiche Windows: nessuna.

## RB-000049 — WindowsService Set

- provider Windows aggiornato a `1.4.0`;
- prima risorsa Set riconosciuta: `WindowsService`;
- mapping Microsoft DSC: `PSDesiredStateConfiguration/Service`;
- proprietà ammesse: nome servizio e stato desiderato `Running`;
- validazione del delta approvato certificata;
- applicazione remota non ancora abilitata;
- connessioni Windows: nessuna;
- modifiche Windows: nessuna.

## RB-000049R — Allineamento provider Windows 1.4.0

- versione dichiarata uniformemente a `1.4.0`;
- `provider.sh`, `get.py`, `test.py`, `set.py` e `VERSION` coerenti;
- source e runtime allineati;
- capability `WindowsService` invariata;
- connessioni Windows: nessuna;
- modifiche Windows: nessuna.

## RB-000051 — Trasporto PSRP provider Windows

- provider Windows aggiornato a `1.5.0`;
- creato `src/providers/windows/transport.py`;
- PyPSRP e WinRM isolati nel trasporto Windows;
- `get.py` non importa più direttamente PyPSRP;
- Get e Test ricertificati sulle tre VM;
- contratto esterno del provider invariato;
- executor condiviso nel Core: non creato;
- modifiche alle VM Windows: nessuna.

WINSRV01|GET=PASS|TEST=PASS|DESIRED_STATE=TRUE|DELTA=0
WINSRV02|GET=PASS|TEST=PASS|DESIRED_STATE=TRUE|DELTA=0
SERVICESRV|GET=PASS|TEST=PASS|DESIRED_STATE=TRUE|DELTA=0

## RB-000052R2 — WindowsService DSC Set

- provider Windows `1.6.0` certificato;
- risultato DSC Test normalizzato sul solo `InDesiredState`;
- campo generico `value` escluso dal contratto;
- Get, Test e Set verificati sulle tre VM;
- delta complessivo: `0`;
- DSC Test remoto: PASS;
- Set remoto invocato: no;
- modifiche Windows: nessuna.

WINSRV01|GET=PASS|TEST=PASS|SET=NO_CHANGES_REQUIRED|DSC_TEST=PASS|DELTA=0
WINSRV02|GET=PASS|TEST=PASS|SET=NO_CHANGES_REQUIRED|DSC_TEST=PASS|DELTA=0
SERVICESRV|GET=PASS|TEST=PASS|SET=NO_CHANGES_REQUIRED|DSC_TEST=PASS|DELTA=0

## RB-000053 — WindowsFeature Set

- provider Windows aggiornato a `1.7.0`;
- capability `WindowsFeature` implementata;
- mapping DSC: `WindowsFeature/PSDesiredStateConfiguration`;
- stato desiderato supportato: `Present`;
- rimozione feature non supportata;
- riavvio automatico non consentito;
- fixture locale Test/Set/Test: PASS;
- Get, Test e Set ricertificati sulle tre VM;
- delta reale complessivo: `0`;
- Set remoto invocato sulle VM: no;
- modifiche Windows: nessuna.

WINSRV01|GET=PASS|TEST=PASS|SET=NO_CHANGES_REQUIRED|DELTA=0
WINSRV02|GET=PASS|TEST=PASS|SET=NO_CHANGES_REQUIRED|DELTA=0
SERVICESRV|GET=PASS|TEST=PASS|SET=NO_CHANGES_REQUIRED|DELTA=0

## RB-000054 — Ricertificazione finale provider Windows

- baseline provider Windows: `1.7.0`;
- architettura ricertificata;
- source e runtime identici;
- isolamento WinRM/PyPSRP in `transport.py`: PASS;
- capability `WindowsService`: PASS;
- capability `WindowsFeature`: PASS;
- fixture combinata Test/Set/Test: PASS;
- Get, Test e Set ricertificati sulle tre VM;
- tutte le VM in desired state;
- delta complessivo: `0`;
- Set remoto invocato: no;
- modifiche Windows: nessuna;
- baseline Windows congelata;
- stato provider: manutenzione.

WINSRV01|PROFILE=DOMAIN_CONTROLLER|GET=PASS|TEST=PASS|SET=NO_CHANGES_REQUIRED|DESIRED_STATE=TRUE|DELTA=0
WINSRV02|PROFILE=DOMAIN_CONTROLLER|GET=PASS|TEST=PASS|SET=NO_CHANGES_REQUIRED|DESIRED_STATE=TRUE|DELTA=0
SERVICESRV|PROFILE=SERVICES_SERVER|GET=PASS|TEST=PASS|SET=NO_CHANGES_REQUIRED|DESIRED_STATE=TRUE|DELTA=0

## RB-000059 — Provider Linux 1.0.0

- creato provider Linux minimale;
- trasporto: OpenSSH tramite `transport.py`;
- autenticazione corrente: password da standard input;
- dipendenze Python esterne: nessuna;
- `provider_get`: implementato;
- `provider_test`: implementato e offline;
- `provider_set`: non implementato;
- inventario e topologia delegati al provider PVE;
- interrogazione systemd tramite JSON e proprietà `show`;
- source/runtime: allineati;
- modifiche ai target Linux: nessuna.

## RB-000060R — Trust SSH target Linux

- identità ED25519 SANDRA creata o verificata;
- fingerprint: `SHA256:nIzmu6lgD8HXhPaRGbwzAEDw3fSRCvv8W7nDu/yVcfM`;
- target Linux certificati: `9`;
- PVE escluso;
- SANDRA esclusa;
- server Windows esclusi;
- host key verificate: PASS;
- chiave pubblica distribuita idempotentemente;
- accesso root con chiave: PASS;
- chiave privata distribuita: no;
- password registrata: no.

PBS|IP=192.168.1.194|HOSTNAME=pbs|HOST_KEY=SHA256:ja+lZUJvR7UYNT9PguFSzICPFSjq4JSOnfBwWbneYZw|KEY_AUTH=PASS|ROOT=PASS|AUTHORIZED_KEY_COUNT=1
TRANSMISSION|IP=192.168.1.192|HOSTNAME=transmission|HOST_KEY=SHA256:QcaioaJwo3xWJ6LO07SDItb+Rg7s8BM5HsbAL7JoyZA|KEY_AUTH=PASS|ROOT=PASS|AUTHORIZED_KEY_COUNT=1
PIHOLE|IP=192.168.1.254|HOSTNAME=pihole|HOST_KEY=SHA256:MTfFInsFLO1hw+167nvsEzmJJQ3ZQNCOjgAFaGqnB88|KEY_AUTH=PASS|ROOT=PASS|AUTHORIZED_KEY_COUNT=1
PIHOLE2|IP=192.168.1.253|HOSTNAME=pihole2|HOST_KEY=SHA256:fFHwNY8ysgaJZ+BvAH1jdhwHHphBE5a1XWAW75sT/v0|KEY_AUTH=PASS|ROOT=PASS|AUTHORIZED_KEY_COUNT=1
PLEX|IP=192.168.1.199|HOSTNAME=plex|HOST_KEY=SHA256:gOq13SkUXKdF8YHLPN9zwqCWiYivRCDfhKgEhMBlO2A|KEY_AUTH=PASS|ROOT=PASS|AUTHORIZED_KEY_COUNT=1
NAVIDROME|IP=192.168.1.198|HOSTNAME=navidrome|HOST_KEY=SHA256:Gv0r92WyqjkeQiCcv3p9Zwp0/OjwVmk5XTjZisVBycQ|KEY_AUTH=PASS|ROOT=PASS|AUTHORIZED_KEY_COUNT=1
SERVARR|IP=192.168.1.195|HOSTNAME=servarr|HOST_KEY=SHA256:K0INFKff62KpUHAtMwkDYq5hXfNR8czV88JQpJ12s20|KEY_AUTH=PASS|ROOT=PASS|AUTHORIZED_KEY_COUNT=1
PASSBOLT|IP=192.168.1.196|HOSTNAME=passbolt|HOST_KEY=SHA256:rtjqdoP/0Eg0OOs9qnb3YZ286LmhKkdjKJXQfwlodfE|KEY_AUTH=PASS|ROOT=PASS|AUTHORIZED_KEY_COUNT=1
NGINX|IP=192.168.1.193|HOSTNAME=nginx|HOST_KEY=SHA256:xwZ2Q8sGRF2a1Wr/qdj13PS1GTXiV1tpVTecSsX8wOY|KEY_AUTH=PASS|ROOT=PASS|AUTHORIZED_KEY_COUNT=1

## RB-000061 — Provider Linux SSH con chiave

- provider Linux aggiornato a `1.1.0`;
- autenticazione SSH: chiave pubblica;
- password rimossa dal flusso `provider_get`;
- strict host key checking: abilitato;
- chiave privata: `/opt/sandra/secrets/ssh/id_ed25519`;
- known_hosts: `/opt/sandra/secrets/ssh/known_hosts`;
- Get e Test certificati sui nove target Linux;
- PVE escluso;
- SANDRA esclusa;
- Windows esclusi;
- delta complessivo: `0`;
- modifiche remote: nessuna.

PBS|GET=PASS|TEST=PASS|KEY_AUTH=PASS|FAILED_UNITS=0|DELTA=0
TRANSMISSION|GET=PASS|TEST=PASS|KEY_AUTH=PASS|FAILED_UNITS=0|DELTA=0
PIHOLE|GET=PASS|TEST=PASS|KEY_AUTH=PASS|FAILED_UNITS=0|DELTA=0
PIHOLE2|GET=PASS|TEST=PASS|KEY_AUTH=PASS|FAILED_UNITS=0|DELTA=0
PLEX|GET=PASS|TEST=PASS|KEY_AUTH=PASS|FAILED_UNITS=1|DELTA=0
NAVIDROME|GET=PASS|TEST=PASS|KEY_AUTH=PASS|FAILED_UNITS=1|DELTA=0
SERVARR|GET=PASS|TEST=PASS|KEY_AUTH=PASS|FAILED_UNITS=1|DELTA=0
PASSBOLT|GET=PASS|TEST=PASS|KEY_AUTH=PASS|FAILED_UNITS=0|DELTA=0
NGINX|GET=PASS|TEST=PASS|KEY_AUTH=PASS|FAILED_UNITS=0|DELTA=0
