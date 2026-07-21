# RA-000002 — Moduli source-safe

## Regola

I moduli Bash di SANDRA devono poter essere caricati più volte nello
stesso processo senza produrre errori o collisioni.

## Vincoli

- vietate variabili top-level dichiarate `readonly`;
- vietati effetti operativi durante `source`;
- il caricamento del modulo deve soltanto definire configurazione e
  funzioni;
- il doppio `source` deve terminare con exit code zero.

## Motivazione

Core, Knowledge, Provider ed Execute possono essere caricati da
componenti differenti nello stesso processo Bash. Il caricamento
ripetuto non deve compromettere l'esecuzione.
