# Next Task

## RB-000015 — Aggiunta certificata proxmox_resources

Estendere il provider con una sola capability:

`proxmox_resources`

Prima della modifica devono essere verificati:

- hash del provider 1.2.0;
- endpoint `/cluster/resources`;
- validità JSON;
- presenza di risorse appartenenti al nodo `pve`.
