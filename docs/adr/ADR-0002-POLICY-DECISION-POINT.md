# ADR-0002 — External policy decision point

## Stato

Accepted as architecture; implementation candidate not installed.

## Decisione

La valutazione delle policy viene separata dall'esecuzione.

Open Policy Agent è il candidato primario perché:

- è un policy engine general-purpose;
- riceve input strutturato;
- separa decisione ed enforcement;
- supporta policy dichiarative;
- produce decision identifier e decision logs;
- supporta bundle versionati e firmabili.

## Fonti ufficiali

- https://www.openpolicyagent.org/docs
- https://www.openpolicyagent.org/docs/management-decision-logs
- https://www.openpolicyagent.org/docs/management-bundles

## Condizione di installazione

OPA verrà installato solo dopo la definizione degli schemi di input/output
e dei test delle prime policy.
