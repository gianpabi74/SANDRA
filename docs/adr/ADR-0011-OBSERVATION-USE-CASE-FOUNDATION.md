# ADR-0011 — Observation Use Case Foundation

## Stato

Accepted and immutable.

## Decisione

SANDRA adotta `ObserveSubject` come primo caso d'uso applicativo.

Il caso d'uso:

- riceve `ObservationRequest`;
- usa esclusivamente l'outbound port `ObservationSource`;
- restituisce `ApplicationResult[ObservationBatch]`;
- verifica che il batch appartenga alla richiesta originaria.

## Confini

Observation raccoglie fatti grezzi.

Observation non:

- qualifica autorità o confidence;
- aggiorna lo stato autorevole;
- valuta policy;
- pianifica;
- esegue;
- verifica una remediation;
- apprende.

Queste responsabilità appartengono ad altre capability costituzionali.

## Tecnologia

Prodotti, protocolli e trasporti saranno implementati da adapter outbound.
