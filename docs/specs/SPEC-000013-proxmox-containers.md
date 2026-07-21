# SPEC-000013 — Proxmox LXC Containers Capability

## Stato

Certified PASS.

## Provider

`/opt/sandra/providers/proxmox/provider.sh`

## Versione

`1.5.0`

## Funzione

`proxmox_containers`

## Comando

`pct list`

## Contratto

La funzione restituisce l'indice dei container LXC del nodo Proxmox.

La verifica richiede:

- output non vuoto;
- intestazione iniziale `VMID`;
- almeno un container osservato;
- VMID numerici e non duplicati.

Non vengono hardcodati VMID, hostname o stati specifici.
