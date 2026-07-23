# ADR-0008 — Constitutional Operational Contracts V1

## Stato

Accepted and immutable.

## Decisione

SANDRA adotta quattro contratti costituzionali:

- Resource Lifecycle Contract V1;
- Evidence Authority Contract V1;
- Reconciliation Concurrency Contract V1;
- Execution Safety Contract V1.

## Motivazione

Questi contratti prevengono:

- promozione non governata dello stato scoperto;
- decisioni basate su evidenze obsolete;
- riconciliazioni concorrenti o stale;
- azioni duplicate;
- retry illimitati;
- esecuzioni senza verifica;
- falsi successi basati sul solo exit code;
- autonomia fuori dai limiti di policy.

## Conseguenze

Application Layer, controller e adapter dovranno implementare questi
contratti senza introdurre eccezioni legate a prodotti specifici.
