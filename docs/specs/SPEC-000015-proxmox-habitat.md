# SPEC-000015 — Proxmox Habitat

## Stato

Certified PASS.

## Output canonici

- `/opt/sandra/habitat/hypervisor/proxmoxve/habitat.json`
- `/opt/sandra/habitat/hypervisor/proxmoxve/habitat.txt`

## Provider richiesto

Proxmox provider `1.6.0`.

## Sorgenti

L'Habitat utilizza esclusivamente funzioni certificate:

- `proxmox_connect`
- `proxmox_version`
- `proxmox_nodes`
- `proxmox_resources`
- `proxmox_vms`
- `proxmox_containers`
- `proxmox_storage`

## Contratto

`habitat.json` conserva ogni oggetto restituito da
`/cluster/resources`, senza whitelist preventiva dei tipi.

Ogni oggetto contiene:

- `id`;
- `type`;
- `node`;
- `name`;
- `status`;
- attributi originali restituiti da Proxmox.

`habitat.txt` fornisce una rappresentazione leggibile degli oggetti e
delle risorse disponibili.
