# Windows Provider Set Contract

## Stato

Scheletro certificato.

Nessuna risorsa modificativa è ancora implementata.

## Input

`provider_set` riceve:

1. il documento JSON prodotto da `provider_test`;
2. un documento JSON di approvazione.

Il documento di approvazione deve contenere:

- `Provider: Windows`;
- `Operation: SetApproval`;
- lo stesso `Target` del Test;
- lo stesso `Profile` del Test;
- esattamente lo stesso `Delta` del Test.

## Regole

- Delta vuoto: `NO_CHANGES_REQUIRED`.
- Delta differente da quello approvato: rifiuto.
- Target o profilo differente: rifiuto.
- Risorsa non implementata: `NOT_IMPLEMENTED`.
- Il provider non decide autonomamente cosa modificare.
- Test deve precedere Set.
- Questa versione non apre connessioni Windows e non modifica sistemi.

## Risorse supportate

Nessuna.

Ogni risorsa modificativa sarà aggiunta e certificata separatamente.
