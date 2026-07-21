# SPEC-000010 — Proxmox Nodes Capability

## Stato

Certified PASS.

## Provider

`/opt/sandra/providers/proxmox/provider.sh`

## Versione provider

`1.2.0`

## Funzione

`proxmox_nodes`

## Contratto

La funzione interroga tramite SSH l'endpoint ufficiale locale:

`pvesh get /nodes --output-format json`

Il risultato deve:

- essere JSON valido;
- essere una lista non vuota;
- contenere il nodo `pve`;
- coincidere semanticamente con il preflight eseguito prima della patch.
