# Core 1.1.1

## Stato

Certified PASS.

## Correzione

Il caricamento ripetuto di Core non azzera più lo stato di un run attivo.

Le variabili preservate durante i source successivi sono:

- `SANDRA_FINALIZED`
- `SANDRA_STATUS`
- `SANDRA_PHASE`
- `SANDRA_START_EPOCH`

## Motivazione

I moduli SANDRA importano Core e Knowledge.
Il source di un provider durante un run non deve alterare identificazione,
stato, fase o tempo iniziale del Run Bundle corrente.

## Verifiche

- sintassi Bash: `PASS`
- assenza di variabili top-level readonly: `PASS`
- source ripetuto fuori da un run: `PASS`
- preservazione stato durante un run: `PASS`
- caricamento provider PBS durante un run: `PASS`
- allineamento sorgente/runtime: `PASS`
