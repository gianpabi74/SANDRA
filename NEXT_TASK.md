# Next Task

## RB-000025 — Execute generico

Sostituire:

`/opt/sandra/execute/proxmox_execute.sh`

con:

`/opt/sandra/execute/execute.sh`

La richiesta dovrà contenere:

- provider;
- operation;
- object_id;
- decision.

`execute` dovrà:

1. validare la richiesta;
2. accettare esclusivamente `ALLOW`;
3. caricare il provider richiesto;
4. invocare l'interfaccia comune;
5. restituire l'esito tecnico;
6. non produrre decisioni.

La prima strategia certificata sarà `pve`.
