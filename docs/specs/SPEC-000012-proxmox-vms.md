# SPEC-000012 — Proxmox QEMU VM Capability

## Stato

Certified PASS.

## Provider

`/opt/sandra/providers/proxmox/provider.sh`

## Versione

`1.4.0`

## Funzione

`proxmox_vms`

## Comando

`qm list`

## Contratto

La funzione restituisce l'indice delle VM QEMU del nodo Proxmox.

La verifica richiede:

- output non vuoto;
- intestazione iniziale `VMID`;
- almeno una VM osservata nell'ambiente reale;
- VMID numerici e non duplicati.

Non vengono hardcodati VMID, nomi o stati specifici.
