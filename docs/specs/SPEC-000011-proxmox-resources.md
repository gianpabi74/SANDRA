# SPEC-000011 — Proxmox Resources Capability

## Stato

Certified PASS.

## Provider

`/opt/sandra/providers/proxmox/provider.sh`

## Versione

`1.3.0`

## Funzione

`proxmox_resources`

## Endpoint

`pvesh get /cluster/resources --output-format json`

## Contratto

La funzione restituisce una lista JSON non vuota.

Ogni risorsa deve possedere:

- `id` non vuoto;
- `type` non vuoto.

La risposta deve contenere:

- l'oggetto `node/pve`;
- almeno una risorsa associata al nodo `pve`.

Non viene applicata alcuna whitelist dei tipi di risorsa. I tipi
restituiti dall'API ufficiale vengono osservati e registrati senza
ipotesi preventive.
