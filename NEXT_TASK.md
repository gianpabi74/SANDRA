# Next Task

## RB-000021 — Validatore policy Proxmox

Implementare una capability deterministica che, dato:

- oggetto;
- operazione richiesta;
- stato dell'Habitat;
- condizioni runtime;

restituisca esclusivamente:

- `ALLOW`;
- `DENY`;
- motivazione;
- regola applicata.

Il validatore non eseguirà ancora modifiche su PVE.
