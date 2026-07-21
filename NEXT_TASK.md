# Next Task

## RB-000022 — Capability start protetta dalla policy

Estendere il provider con una prima capability operativa:

`proxmox_start`

Requisiti obbligatori:

- decisione `ALLOW` del validatore;
- oggetto esistente nell'Habitat;
- massimo tre tentativi;
- verifica dello stato dopo ogni tentativo;
- risultato `CRITICAL` dopo il terzo fallimento;
- Journal ed evidenze complete.
