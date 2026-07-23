# ADR-0001 — Controller and reconciliation pattern

## Stato

Accepted.

## Decisione

Il comportamento centrale segue il controller pattern:

observed state -> desired/governed state -> reconciliation -> verification.

Si preferiscono controller piccoli, ciascuno responsabile di un aspetto
specifico dello stato, evitando un motore monolitico.

## Fonti ufficiali

- https://kubernetes.io/docs/concepts/architecture/controller/
- https://kubernetes.io/docs/concepts/extend-kubernetes/operator/

## Conseguenze

- il runtime non dipende dalla piattaforma corrente;
- gli adapter implementano integrazioni concrete;
- ogni ciclo è idempotente o rileva esplicitamente quando non può esserlo;
- errori e risultati intermedi sono persistiti.
