# Costituzione — Scheletro canonico SANDRA

Stato: APPROVATO — GRANITICO — INVIOLABILE

## Struttura top-level definitiva

- cli
- core
- config
- decision
- policy
- execute
- provider
- verify
- remember
- knowledge
- habitat
- report
- docker
- artifacts

Non possono essere create altre directory top-level senza modifica
costituzionale esplicitamente approvata.

## Pipeline canonica

decision → policy → execute → provider → verify → remember → knowledge

## Habitat canonico iniziale

- habitat/hypervisor/proxmoxve
- habitat/internals/proxmox/PBS
- habitat/internals/linux/pihole
- habitat/internals/windows/WINSRV01
- habitat/externals/mac-biondra

## Regole inviolabili

1. Execute non decide.
2. Policy restituisce ALLOW oppure DENY.
3. Provider traduce operazioni nel dominio tecnico.
4. Verify verifica e non modifica sistemi.
5. Remember registra esclusivamente fatti verificati.
6. Report non modifica sistemi.
7. Docker contiene strumenti containerizzati futuri.
8. Password e chiavi private non entrano in Knowledge.
9. I moduli Bash non usano variabili top-level readonly.
10. Lo scheletro top-level è congelato.
