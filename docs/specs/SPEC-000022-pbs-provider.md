# SPEC-000022 — Provider PBS

## Stato

Certified PASS.

## Percorso canonico

`/opt/sandra/provider/pbs/provider.sh`

## Versione

`1.0.0`

## Interfaccia

- `provider_connect`
- `provider_version`
- `provider_datastores`
- `provider_garbage_collections`
- `provider_verify_jobs`
- `provider_prune_jobs`
- `provider_sync_jobs`
- `provider_remotes`
- `provider_acls`
- `provider_users`

## Responsabilità

Il provider traduce richieste tecniche in comandi PBS read-only.
Non prende decisioni, non interpreta policy e non modifica PBS.

## Source safety

Il provider:

- importa Core e Knowledge;
- non contiene variabili top-level `readonly`;
- può essere caricato più volte;
- non esegue operazioni durante `source`.

## Capability certificate

- connessione
- versione
- datastore
- garbage collection
- verify job
- prune job
- sync job
- remote
- ACL
- utenti
