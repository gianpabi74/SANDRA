# SANDRA — Current State

Aggiornato: `2026-07-22T14:08:59Z`

Questo documento rappresenta soltanto lo stato certificato corrente.
La cronologia è sotto `journal/`.

## Repository

- URL: https://github.com/gianpabi74/SANDRA
- branch: `main`
- stato canonico: `STATE.json`

## Core

- versione: `1.1.1`
- stato: stabile
- Run Bundle, evidence, journaling e Knowledge/Git: operativi

## Provider PVE

- versione: `1.7.0`
- stato: operativo
- responsabilità: inventario e topologia

## Provider PBS

- versione: `1.0.0`
- stato: read-only operativo

## Provider Windows

- versione: `1.7.0`
- stato: congelato e in manutenzione
- Get/Test/Approval/Set: certificati
- WindowsService: certificato
- WindowsFeature: certificato

## Provider Linux

- versione: `1.1.0`
- trasporto SSH con chiave pubblica
- StrictHostKeyChecking obbligatorio
- Get remoto: certificato
- Test offline: certificato
- Set: assente
- target certificati: 9
- delta invarianti: 0
- modifiche remote durante la certificazione: nessuna

## Target Linux

- PBS — `192.168.1.194`
- TRANSMISSION — `192.168.1.192`
- PIHOLE — `192.168.1.254`
- PIHOLE2 — `192.168.1.253`
- PLEX — `192.168.1.199`
- NAVIDROME — `192.168.1.198`
- SERVARR — `192.168.1.195`
- PASSBOLT — `192.168.1.196`
- NGINX — `192.168.1.193`

PVE, SANDRA e i server Windows sono esclusi dal provider Linux.

## Stato systemd noto

- PLEX: degraded, `motd-news.service` fallita
- NAVIDROME: degraded, `motd-news.service` fallita
- SERVARR: degraded, `motd-news.service` fallita
- altri target: stato operativo osservato

## Certificazione corrente

- RunBook: `RB-000061AR`
- Journal: `journal/2026/07/RB-000061AR-20260722T140859Z-b9afd4ec.md`

## Prossimo gate

`RB-000062 — Baseline certificata dei servizi Linux`
