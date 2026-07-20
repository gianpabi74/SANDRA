# ADR-000001 — Separazione tra Runtime e Knowledge

## Stato

Accepted

## Decisione

Il runtime operativo e la memoria ingegneristica sono separati.

- Runtime: `/opt/sandra`
- Knowledge: `/opt/sandra/knowledge`

Git sincronizzerà la Knowledge, non lo stato operativo dinamico.

## Conseguenze

Il progetto può essere ricostruito senza dipendere dalla cronologia
della chat e senza pubblicare secret o stato sensibile.
