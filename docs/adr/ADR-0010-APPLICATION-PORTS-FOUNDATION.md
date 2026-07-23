# ADR-0010 — Application Ports Foundation V1

## Stato

Accepted and immutable.

## Decisione

SANDRA adotta una fondazione applicativa composta da:

- messaggi immutabili `Command` e `Query`;
- result envelope deterministico;
- inbound port `CommandHandler`;
- inbound port `QueryHandler`;
- outbound port `Repository`;
- outbound port `EventBus`;
- outbound port `UnitOfWork`;
- contratto generico `UseCase`.

## Confini

Il gate non introduce:

- use case concreti;
- controller;
- adapter outbound;
- prodotti;
- trasporti;
- logica infrastrutturale.

## Dipendenze

L'Application Layer può dipendere dal Domain.

Domain non dipende da Application.

Application non dipende da Controller, Adapter o Bootstrap.
