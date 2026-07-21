# SPEC-000014 — Proxmox Storage Capability

## Stato

Certified PASS.

## Provider

`/opt/sandra/providers/proxmox/provider.sh`

## Versione

`1.6.0`

## Funzione

`proxmox_storage`

## Comando

`pvesm status`

## Contratto

La funzione restituisce lo stato degli storage configurati in Proxmox.

La verifica richiede:

- output con intestazione e almeno una riga storage;
- nomi storage non vuoti e non duplicati;
- stessa intestazione osservata nel preflight;
- stesso insieme di storage osservato nel preflight.

Non vengono hardcodati nomi, tipi, dimensioni o percentuali.
