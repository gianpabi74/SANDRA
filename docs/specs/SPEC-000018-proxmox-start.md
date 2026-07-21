# SPEC-000018 — Proxmox Start Capability

## Stato

Safe path certified PASS.

## Provider

`/opt/sandra/providers/proxmox/provider.sh`

## Versione

`1.7.0`

## Funzione

`proxmox_start OBJECT_ID`

`OBJECT_ID` deve avere uno dei formati:

- `qemu/VMID`
- `lxc/VMID`

## Comportamento

Se l'oggetto è già `running`, la funzione restituisce:

`ALREADY_RUNNING`

senza eseguire alcun comando di start.

Se l'oggetto è `stopped`, la funzione:

1. tenta lo start;
2. attende cinque secondi;
3. verifica lo stato;
4. ripete fino a un massimo di tre tentativi;
5. restituisce `CRITICAL` se l'oggetto resta fermo.

## Policy

La funzione è una primitiva del provider.

L'esecutore SANDRA deve ottenere una decisione `ALLOW` dal validatore
prima di invocarla.

## Certificazione RB-000022

È stato certificato il ramo sicuro `ALREADY_RUNNING` sulla VM SANDRA
`qemu/221`.

Nessun guest è stato fermato, avviato o riavviato durante il test.

Il ramo di transizione `stopped → running` verrà certificato sulla prima
occorrenza reale di un guest fermo oppure su un oggetto di test
esplicitamente autorizzato.
