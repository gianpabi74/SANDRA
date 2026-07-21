# SPEC-000009 — Proxmox Version Capability

## Stato

Certified PASS.

## Provider

`/opt/sandra/provider/proxmox/provider.sh`

## Versione provider

`1.1.0`

## Funzione

`proxmox_version`

## Contratto

La funzione interroga tramite SSH l'endpoint locale ufficiale:

`pvesh get /version --output-format json`

Il risultato deve essere JSON valido e coincidere semanticamente con
l'output ottenuto dal preflight eseguito prima della modifica.
