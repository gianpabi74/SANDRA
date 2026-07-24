# SANDRA — Baseline globale certificata

> GENERATED FILE — DO NOT EDIT MANUALLY  
> Source: `STATE.json`

Aggiornato: `2026-07-24T07:09:16Z`

Repository: https://github.com/gianpabi74/SANDRA

Branch: `main`

RunBook corrente: `R3-000013B`

Journal corrente: `journal/2026/07/R3-000013B-20260724T070913Z-8b6b6770.md`

## Principi permanenti

- documentazione ufficiale come fonte primaria
- dati oggettivi prima del codice
- audit chirurgico prima delle assunzioni
- motore deterministico e nessuna AI decisionale
- Bash piccoli, accurati e con un solo obiettivo
- briefing proporzionati e roadmap stabile
- nessuna complessità senza valore operativo
- SANDRA finalizzata al governo autonomo dell'Habitat
- stato corrente riscritto e storia separata
- Knowledge e GitHub aggiornati nella stessa transazione
- controller e reconciliation loop come modello operativo
- policy decision separata dall'enforcement
- autonomia delegata dalle policy
- strumenti maturi orchestrati, non reinventati
- nessuna correzione ad intuito
- Architecture Constitution V1 applica il principio di Architettura Granitica ed è immutabile fino alla fine del progetto
- nessuna rinomina o movimento dei layer per preferenza o intuizione
- Security è una famiglia funzionale permanente

## Core

- versione: `1.2.0`;
- stato: `stable`;
- capability:
- Run Bundle
- evidence
- journaling
- Knowledge
- Git synchronization
- expected failure isolation
- unhandled error certification guard

## Provider PVE

- versione: `1.7.0`;
- stato: `operational`;
- responsabilità:
- inventory
- topology
- VMID
- VM
- LXC
- resource state

## Provider PBS

- versione: `1.0.0`;
- stato: `read_only_operational`;
- target: `192.168.1.194`.

## Provider Windows

- versione: `1.7.0`;
- stato: `frozen_maintenance`;
- baseline: `docs/providers/windows/BASELINE-1.7.0.md`;
- capability:
- Get
- Test
- Approval
- Set
- WindowsService
- WindowsFeature

## Provider Linux

- versione: `1.1.1`;
- stato: `capability_development`;
- trasporto: `OpenSSH`;
- autenticazione: `PublicKey`;
- StrictHostKeyChecking: `true`;
- Get: `certified`;
- Test: `certified_offline`;
- Set: `absent`;
- target certificati:
- PBS
- TRANSMISSION
- PIHOLE
- PIHOLE2
- PLEX
- NAVIDROME
- SERVARR
- PASSBOLT
- NGINX

## Prossimo gate

`R3-000013B` — Resource Graph Use Case Foundation Publication

Tipo: `application_vertical_contract_publication`.
