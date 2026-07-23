# ADR-0007 — Architecture GRANITA Freeze V1

## Stato

Accepted and immutable until project completion.

## Decisione

SANDRA adotta definitivamente:

- Ports and Adapters;
- controller/reconciliation pattern;
- Resource Model con apiVersion, kind, metadata, spec e status;
- separazione fra decisione di policy ed enforcement;
- dependency direction verso il dominio;
- bootstrap come composition root;
- test unitari, contrattuali e d'integrazione;
- Security come famiglia funzionale permanente.

## Prodotti concreti

- PVE e VMware: adapter compute.
- Linux e Windows: adapter operating_system.
- PBS: adapter backup.
- OpenVAS/Greenbone: adapter security.
- OPA: adapter policy_engine.
- Database: adapter persistence.

Il codice storico in `src/providers`, `src/runtime` e `src/domain`
rimane patrimonio di migrazione e non definisce la struttura canonica.
