# SPEC-000020 — Provider PVE

## Stato

Certified PASS.

## Percorso canonico

`/opt/sandra/providers/pve/provider.sh`

## Versione

`1.7.0`

## Interfaccia

- `provider_connect`
- `provider_version`
- `provider_nodes`
- `provider_resources`
- `provider_vms`
- `provider_containers`
- `provider_storage`
- `provider_start`

## Source safety

Il provider:

- non contiene variabili top-level `readonly`;
- può essere caricato più volte;
- non esegue operazioni durante `source`.

## Compatibilità

Il vecchio percorso:

`/opt/sandra/providers/proxmox/provider.sh`

è un adapter temporaneo.

Verrà rimosso soltanto dopo l'installazione e la certificazione del
componente `execute` generico.

## Directory legacy

La directory:

`/opt/sandra/providers/hypervisor/proxmox/`

era già presente prima della migrazione e non è stata modificata da
RB-000024. Sarà valutata separatamente.
