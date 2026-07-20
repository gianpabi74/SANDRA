# SPEC-000003 — Knowledge Synchronization Contract

## Stato

Frozen.

## Scopo

Garantire che la Knowledge canonica presente in:

`/opt/sandra/knowledge`

sia sincronizzata con il remoto Git senza pubblicare stati parziali.

## Percorso ordinario

Ogni Runbook permanente deve:

1. modificare il runtime o la Knowledge;
2. verificare il risultato;
3. aggiornare la documentazione pertinente;
4. creare il Journal;
5. creare un commit identificato dal Runbook;
6. eseguire il push;
7. verificare che `HEAD` coincida con `origin/main`.

## Percorso di recupero

Il timer:

`sandra-knowledge-sync.timer`

attiva ogni cinque minuti:

`sandra-knowledge-sync.service`

Il servizio utilizza:

`/usr/local/libexec/sandra-knowledge-sync-retry`

## Vincoli del worker

Il worker:

- non crea commit;
- non modifica file;
- non esegue merge, pull, rebase o force push;
- non opera se la working tree non è pulita;
- non opera in presenza di divergenza;
- ritenta soltanto il push di commit locali già completi;
- verifica l'identità tra `HEAD` e `origin/main` dopo il push.

Il worker non è un Runbook e non genera artefatti periodici. Generare un
artefatto ogni cinque minuti senza una modifica reale produrrebbe rumore
operativo privo di valore.
