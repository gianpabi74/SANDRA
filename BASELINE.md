# SANDRA — Baseline globale certificata

> GENERATED FILE — DO NOT EDIT MANUALLY  
> Source: `STATE.json`

Aggiornato: `2026-07-22T14:53:46Z`

Repository: https://github.com/gianpabi74/SANDRA

Branch: `main`

RunBook corrente: `RB-000061C1`

Journal corrente: `journal/2026/07/RB-000061C1-20260722T145345Z-4d2a9e3a.md`

## Principi permanenti

- motore deterministico
- nessuna AI decisionale
- un solo owner per responsabilità
- provider indipendenti
- nessun secret nel repository
- nessuna complessità senza valore operativo
- audit prima dell'implementazione
- nessun cambio di architettura senza requisito concreto

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

- versione: `1.1.0`;
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

`RB-000062` — Baseline certificata dei servizi Linux

Tipo: `remote_read_only_audit`.
