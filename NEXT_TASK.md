# Next Task

## RB-000016 — Aggiunta certificata proxmox_vms

Estendere il provider con una sola capability:

`proxmox_vms`

Il preflight dovrà verificare il comando `qm list` e osservare
oggettivamente struttura e contenuto dell'ambiente reale, senza
hardcodare VMID o nomi specifici come requisito generale.
