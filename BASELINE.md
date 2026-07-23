# SANDRA — Baseline globale certificata

> GENERATED FILE — DO NOT EDIT MANUALLY  
> Source: `STATE.json`

Aggiornato: `2026-07-23T09:14:53Z`

Repository: https://github.com/gianpabi74/SANDRA

Branch: `main`

RunBook corrente: `RB-000069B3A`

Journal corrente: `journal/2026/07/RB-000069B3A-20260723T091449Z-e114a190.md`

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

## Core

- versione: `1.1.1`;
- stato: `stable`;
- capability:
- Run Bundle
- evidence
- journaling
- Knowledge
- Git synchronization

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

`RB-000069` — Architecture Baseline V2

Tipo: `engineering_knowledge_migration`.
