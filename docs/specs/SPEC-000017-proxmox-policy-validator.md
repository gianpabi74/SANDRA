# SPEC-000017 — Proxmox Policy Validator

## Stato

Certified PASS.

## Percorso

`/opt/sandra/policy/pve_validate.py`

## Input

Il validatore riceve:

- policy Proxmox;
- Habitat Proxmox;
- richiesta JSON;
- stato dei membri dei gruppi ridondanti;
- condizioni runtime necessarie.

## Output

Il risultato contiene esclusivamente una decisione:

- `ALLOW`;
- `DENY`.

Sono sempre presenti:

- motivazione;
- regola applicata;
- oggetto;
- operazione.

## Comportamento

Il validatore:

- nega oggetti sconosciuti;
- protegge i gruppi Active Directory e DNS Resolver;
- protegge PBS durante backup attivi;
- protegge PLEX e NAVIDROME durante streaming attivi;
- nega delete e destroy automatici;
- applica la policy predefinita agli altri oggetti;
- non esegue alcuna modifica su PVE.
