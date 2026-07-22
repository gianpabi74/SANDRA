# SANDRA — Current State

> GENERATED FILE — DO NOT EDIT MANUALLY  
> Source: `STATE.json`

Aggiornato: `2026-07-22T16:04:53Z`

## Repository

- URL: https://github.com/gianpabi74/SANDRA
- branch: `main`
- stato canonico: `STATE.json`

## Core

- versione: `1.1.1`
- stato: `stable`

## Provider PVE

- versione: `1.7.0`
- stato: `operational`
- responsabilità: inventario e topologia

## Provider PBS

- versione: `1.0.0`
- stato: `read_only_operational`

## Provider Windows

- versione: `1.7.0`
- stato: `frozen_maintenance`
- capability:
- Get
- Test
- Approval
- Set
- WindowsService
- WindowsFeature

## Provider Linux

- versione: `1.1.1`
- stato: `capability_development`
- trasporto: `OpenSSH`
- autenticazione: `PublicKey`
- Get: `certified`
- Test: `certified_offline`
- Set: `absent`
- delta invarianti: `0`

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

Esclusi:

- PVE
- SANDRA
- Windows systems

## Stato systemd noto

- PLEX: degraded — `motd-news.service`
- NAVIDROME: degraded — `motd-news.service`
- SERVARR: degraded — `motd-news.service`

## Certificazione corrente

- RunBook: `RB-000062R3`
- Journal: `journal/2026/07/RB-000062R3-20260722T160452Z-796958a1.md`

## Prossimo gate

`RB-000062` — Risoluzione deterministica oggetto-servizio Linux
