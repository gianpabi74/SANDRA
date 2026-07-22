# Costituzione della continuità della Knowledge

## Requisito

Una nuova chat deve poter riprendere SANDRA fornendo il solo link al
repository ufficiale e poche istruzioni operative. Tutte le informazioni
vere, correnti e certificate devono essere versionate su GitHub.

Repository ufficiale:

`https://github.com/gianpabi74/SANDRA`

Branch autorevole:

`main`

## Fonte di verità

`STATE.json` è lo stato vivo canonico e machine-readable del progetto.

I seguenti documenti sono viste umane derivate e devono essere coerenti con
`STATE.json`:

- `START-HERE.md`;
- `BASELINE.md`;
- `CURRENT_STATE.md`;
- `NEXT_TASK.md`;
- `docs/roadmap/ROADMAP.md`;
- `CHAT-HANDOFF.md`.

I Journal sotto `journal/` sono la cronologia certificata e immutabile.

## Regola di aggiornamento

I documenti vivi non sono diari e non devono essere aggiornati tramite
append incrementale. A ogni RunBook che cambia stato, codice, contratti o
roadmap devono essere riscritti integralmente.

Una RunBook è conclusa soltanto quando:

1. il Journal della RunBook esiste;
2. `STATE.json` descrive la RunBook corrente e il prossimo gate;
3. tutte le viste umane sono coerenti con `STATE.json`;
4. la validazione ordinaria e quella di continuità passano;
5. indice, commit, push e verifica del remoto sono completati;
6. HEAD locale e `origin/main` coincidono.

## Gate obbligatorio

`knowledge_sync` deve rifiutare commit e push quando la validazione di
continuità fallisce.

## Avvio di una nuova chat

La nuova sessione deve leggere nell'ordine:

1. `START-HERE.md`;
2. `STATE.json`;
3. `BASELINE.md`;
4. `CURRENT_STATE.md`;
5. `NEXT_TASK.md`;
6. `docs/roadmap/ROADMAP.md`;
7. il Journal indicato da `STATE.json`;
8. i contratti richiamati dal prossimo task.

La sessione non deve ricostruire lo stato interpretando la cronologia.

## Separazione fra stato e storia

- Stato corrente: `STATE.json` e documenti vivi.
- Storia: Journal immutabili e baseline congelate dei provider.
- Codice e contratti: file versionati nel repository.

Questa separazione è un requisito costituzionale permanente di SANDRA.
