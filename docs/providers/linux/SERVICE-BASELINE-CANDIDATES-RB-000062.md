# RB-000062 — Candidati servizi Linux

> Stato: `AWAITING HUMAN APPROVAL`  
> Run ID: `RB-000062-20260722T152004Z-ec5f3393`  
> Audit: remoto e read-only

Questo documento contiene esclusivamente una proposta deterministica.
Nessun servizio è ancora inserito nei profili Desired State.

## Regole applicate

- unità classificata come `application`;
- unità caricata da systemd;
- file unità persistente;
- nessuna unità generata sotto `/run`;
- nessuna unità template o istanza con `@`;
- stato del file compatibile con una futura gestione dichiarativa.

## Riepilogo

- host auditati: `9`;
- unità osservate: `1095`;
- unità fallite osservate: `2`;
- candidati proposti: `9`;
- errori di raccolta: `0`;
- modifiche remote: `NESSUNA`.

## NAVIDROME

- indirizzo: `192.168.1.198`;
- hostname: `navidrome`;
- unità osservate: `127`;
- unità fallite: `1`;
- candidati: `2`;

### Unità fallite osservate

- `motd-news.service`

### Servizi candidati

| Servizio | Stato | UnitFileState | FragmentPath |
|---|---|---|---|
| `navidrome.service` | `active/running` | `enabled` | `/etc/systemd/system/navidrome.service` |
| `proxmox-regenerate-snakeoil.service` | `inactive/dead` | `enabled` | `/etc/systemd/system/proxmox-regenerate-snakeoil.service` |

## NGINX

- indirizzo: `192.168.1.193`;
- hostname: `nginx`;
- unità osservate: `88`;
- unità fallite: `0`;
- candidati: `1`;

### Servizi candidati

| Servizio | Stato | UnitFileState | FragmentPath |
|---|---|---|---|
| `proxmox-regenerate-snakeoil.service` | `inactive/dead` | `enabled` | `/etc/systemd/system/proxmox-regenerate-snakeoil.service` |

## PASSBOLT

- indirizzo: `192.168.1.196`;
- hostname: `passbolt`;
- unità osservate: `105`;
- unità fallite: `0`;
- candidati: `0`;

### Servizi candidati

_Nessun candidato proposto._

## PBS

- indirizzo: `192.168.1.194`;
- hostname: `pbs`;
- unità osservate: `151`;
- unità fallite: `0`;
- candidati: `0`;

### Servizi candidati

_Nessun candidato proposto._

## PIHOLE

- indirizzo: `192.168.1.254`;
- hostname: `pihole`;
- unità osservate: `102`;
- unità fallite: `0`;
- candidati: `1`;

### Servizi candidati

| Servizio | Stato | UnitFileState | FragmentPath |
|---|---|---|---|
| `pihole-FTL.service` | `active/running` | `enabled` | `/etc/systemd/system/pihole-FTL.service` |

## PIHOLE2

- indirizzo: `192.168.1.253`;
- hostname: `pihole2`;
- unità osservate: `102`;
- unità fallite: `0`;
- candidati: `1`;

### Servizi candidati

| Servizio | Stato | UnitFileState | FragmentPath |
|---|---|---|---|
| `pihole-FTL.service` | `active/running` | `enabled` | `/etc/systemd/system/pihole-FTL.service` |

## PLEX

- indirizzo: `192.168.1.199`;
- hostname: `plex`;
- unità osservate: `127`;
- unità fallite: `1`;
- candidati: `1`;

### Unità fallite osservate

- `motd-news.service`

### Servizi candidati

| Servizio | Stato | UnitFileState | FragmentPath |
|---|---|---|---|
| `proxmox-regenerate-snakeoil.service` | `inactive/dead` | `enabled` | `/etc/systemd/system/proxmox-regenerate-snakeoil.service` |

## SERVARR

- indirizzo: `192.168.1.195`;
- hostname: `servarr`;
- unità osservate: `128`;
- unità fallite: `0`;
- candidati: `3`;

### Servizi candidati

| Servizio | Stato | UnitFileState | FragmentPath |
|---|---|---|---|
| `prowlarr.service` | `active/running` | `enabled` | `/etc/systemd/system/prowlarr.service` |
| `proxmox-regenerate-snakeoil.service` | `inactive/dead` | `enabled` | `/etc/systemd/system/proxmox-regenerate-snakeoil.service` |
| `radarr.service` | `active/running` | `enabled` | `/etc/systemd/system/radarr.service` |

## TRANSMISSION

- indirizzo: `192.168.1.192`;
- hostname: `transmission`;
- unità osservate: `165`;
- unità fallite: `0`;
- candidati: `0`;

### Servizi candidati

_Nessun candidato proposto._

## Gate

La baseline non è approvata automaticamente.

Prima di `RB-000063` è richiesta una decisione umana esplicita
sui servizi da includere o escludere.
