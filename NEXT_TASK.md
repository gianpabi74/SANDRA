# Next Task

## RB-000017 — Aggiunta certificata proxmox_containers

Estendere il provider con una sola capability:

`proxmox_containers`

Il preflight dovrà verificare `pct list` osservando la struttura reale
dell'output, senza hardcodare VMID, hostname o stato dei container.
