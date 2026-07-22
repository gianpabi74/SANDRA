# Costituzione della continuità della Knowledge

## Requisito

Una nuova chat deve poter riprendere SANDRA fornendo il link al
repository ufficiale e poche istruzioni.

Tutte le informazioni vere, correnti e certificate devono essere
versionate nel repository:

`https://github.com/gianpabi74/SANDRA`

Branch autorevole:

`main`

## Sorgente viva canonica

`STATE.json` è l’unica sorgente viva canonica dello stato del
progetto.

Contiene in forma machine-readable:

- stato del Core;
- versioni e stato dei provider;
- capability certificate;
- target;
- esclusioni;
- osservazioni operative correnti;
- roadmap;
- prossimo task;
- certificazione corrente;
- Journal corrente.

## Viste generate

I seguenti file sono generati esclusivamente da `STATE.json`
tramite `generate_views.py`:

- `START-HERE.md`;
- `BASELINE.md`;
- `CURRENT_STATE.md`;
- `NEXT_TASK.md`;
- `docs/roadmap/ROADMAP.md`;
- `CHAT-HANDOFF.md`.

Questi file:

- non sono sorgenti indipendenti;
- non devono essere modificati manualmente;
- non devono essere aggiornati tramite append;
- devono essere rigenerati integralmente;
- devono contenere l’avviso `GENERATED FILE`.

Qualunque differenza rispetto alla generazione deterministica è
considerata drift e deve bloccare la sincronizzazione.

## Storia immutabile

I Journal sotto `journal/` costituiscono la cronologia certificata.

Un Journal concluso non viene modificato.

Le baseline congelate dei provider sono anch’esse immutabili.

## Ciclo obbligatorio di ogni RunBook

Una RunBook che modifica stato, codice, contratti o roadmap deve:

1. aggiornare `STATE.json`;
2. creare il proprio Journal;
3. eseguire `knowledge_generate_views`;
4. eseguire `knowledge_continuity_validate`;
5. eseguire `knowledge_validate`;
6. rigenerare l’indice;
7. eseguire `knowledge_sync`;
8. verificare che HEAD locale e `origin/main` coincidano.

## Protezione della sincronizzazione

`knowledge_sync` deve sempre:

1. rigenerare le viste;
2. validare `STATE.json`;
3. verificare che le viste generate non abbiano drift;
4. rifiutare commit e push in caso di incoerenza.

## Avvio di una nuova chat

La nuova sessione deve leggere:

1. `START-HERE.md`;
2. `STATE.json`;
3. `BASELINE.md`;
4. `CURRENT_STATE.md`;
5. `NEXT_TASK.md`;
6. `docs/roadmap/ROADMAP.md`;
7. il Journal indicato in `STATE.json`.

La sessione non deve ricostruire lo stato interpretando tutta la
cronologia.

## Regola permanente

Lo stato si modifica esclusivamente aggiornando `STATE.json`.

La storia si conserva esclusivamente nei Journal.

Questa separazione è congelata costituzionalmente.
