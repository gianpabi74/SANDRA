# SPEC-000001 — Runtime Core Contract

## Scopo

`/opt/sandra/core/core.sh` è l’unica libreria Bash caricabile dai
runbook SANDRA.

## Responsabilità

Il Core gestisce:

- modalità Bash rigorosa;
- umask;
- identificazione univoca del run;
- lock esclusivo;
- logging;
- directory delle evidenze;
- gestione errori;
- certificazione;
- artefatto `.tar.gz`;
- export verso il Mac;
- verifica di dimensione e SHA-256.

## Interfaccia pubblica

- `sandra_begin RUNBOOK_ID TITLE`
- `sandra_log LEVEL MESSAGE`
- `sandra_require_command COMMAND`
- `sandra_require_file PATH`
- `sandra_assert COMMAND ...`
- `sandra_capture NAME COMMAND ...`
- `sandra_fail MESSAGE`
- `sandra_end PASS`

## Path canonici

Core:

`/opt/sandra/core/core.sh`

Configurazione:

`/opt/sandra/config/habitat.conf`

Artefatti:

`/opt/sandra/artifacts`

Stato dei run:

`/var/lib/sandra/runs`
