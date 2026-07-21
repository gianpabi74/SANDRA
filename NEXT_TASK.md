# Next Task

## RB-000023 — Esecutore start policy-gated

Creare un comando SANDRA che:

1. aggiorna l'Habitat;
2. individua VM e LXC in stato `stopped`;
3. richiede `ALLOW` al validatore;
4. invoca `proxmox_start`;
5. registra `STARTED`, `ALREADY_RUNNING` o `CRITICAL`;
6. non interviene su oggetti non autorizzati.

Nessun oggetto sarà spento artificialmente per eseguire il test.
