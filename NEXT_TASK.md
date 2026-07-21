# Next Task

## RB-000018 — Aggiunta certificata proxmox_storage

Estendere il provider con una sola capability:

`proxmox_storage`

Il preflight dovrà verificare `pvesm status` osservando la struttura
reale dell'output, senza hardcodare nomi, tipi o capacità specifiche.
