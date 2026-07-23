# ADR-0006 — Capability, policy and enforcement separation

## Stato

Accepted.

## Decisione

- Capability descrive l'operazione astratta.
- Policy assegna authority, condizioni e limiti.
- Policy Decision registra l'esito.
- Execution Plan traduce la decisione in passi immutabili.
- Adapter ed executor applicano il piano.
- Verifier dimostra il risultato.

Il motore di policy resta separato dall'enforcement.

Open Policy Agent rimane il candidato primario, ma non viene installato
finché input, output e primi test non sono definiti.

## Riferimenti ufficiali

- https://www.openpolicyagent.org/docs
- https://www.openpolicyagent.org/docs/philosophy
- https://www.openpolicyagent.org/docs/management-decision-logs
