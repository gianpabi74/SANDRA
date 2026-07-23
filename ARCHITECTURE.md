# SANDRA — Architettura corrente

## Scopo

Questo documento descrive esclusivamente l'architettura vigente.

La storia appartiene a Git, Journal, ADR e artifact. I documenti
canonici correnti devono rappresentare il presente e devono essere
riscritti quando SANDRA evolve.

## Missione architetturale

SANDRA è un runtime deterministico per il governo operativo
dell'Habitat.

La V2 deve osservare, verificare, decidere, operare e registrare
attraverso contratti espliciti e interfacce ufficiali.

Il Core rimane neutrale rispetto all'Habitat. Le implementazioni
specifiche appartengono ai provider.

## Componenti vigenti

### Core

Path:

`/opt/sandra/core/core.sh`

Responsabilità:

- ciclo di vita delle RunBook;
- lock, log ed error handling;
- evidenze e certificazione;
- creazione ed esportazione degli artifact.

Il Core non decide identità, roadmap o capability dei provider.

### Knowledge

Path:

`/opt/sandra/knowledge/knowledge.sh`

Responsabilità:

- validazione della Knowledge;
- controllo dei contenuti vietati;
- commit e push;
- verifica della sincronizzazione GitHub;
- caricamento del modulo di continuità.

La Knowledge non contiene secret e non sostituisce il futuro stato
operativo dell'Habitat.

### Continuità

Path operativo:

`/opt/sandra/knowledge/continuity.sh`

Sorgente canonica:

`/opt/sandra/knowledge/src/knowledge/continuity.sh`

L'entrypoint operativo è un collegamento simbolico relativo alla
sorgente canonica. Runtime e sorgente devono essere byte-identici.

Responsabilità:

- generazione delle viste correnti;
- verifica della coerenza con `STATE.json`;
- continuità fra sessioni;
- sincronizzazione completa della Knowledge.

Il gate corrente deve provenire soltanto da `STATE.json` e non deve
essere scritto direttamente nel modulo.

### Generatore

Path:

`/opt/sandra/knowledge/generate_views.py`

È l'unico generatore autorizzato delle viste canoniche.

A parità di `STATE.json` deve produrre lo stesso risultato.

### Stato progettuale canonico

Path:

`/opt/sandra/knowledge/STATE.json`

Contiene lo stato progettuale machine-readable:

- missione e principi vigenti;
- componenti e versioni;
- provider certificati;
- roadmap;
- singolo gate corrente;
- contratto di continuità.

Non è il futuro registro operativo degli oggetti dell'Habitat.

### Viste generate

Le viste correnti sono:

- `START-HERE.md`;
- `BASELINE.md`;
- `CURRENT_STATE.md`;
- `NEXT_TASK.md`;
- `docs/roadmap/ROADMAP.md`;
- `CHAT-HANDOFF.md`.

Sono derivate da `STATE.json`, descrivono il presente e non devono
essere modificate manualmente.

### Project Charter

Path:

`/opt/sandra/knowledge/PROJECT_CHARTER.md`

Contiene missione, Costituzione, principi, gate e Definition of Done.

### Provider

Root operativo:

`/opt/sandra/provider`

Root sorgente nella Knowledge:

`/opt/sandra/knowledge/src/providers`

Ogni provider dichiarato operativo deve possedere una sorgente
versionata sotto questa root. Il deployment operativo deve essere
verificabile rispetto alla sorgente canonica mediante confronto
byte-per-byte.

I provider adattano SANDRA alle interfacce ufficiali delle tecnologie.
Raccolgono fatti e implementano capability nel proprio perimetro.

Provider correnti:

- PVE;
- PBS;
- Windows;
- Linux.

### RunBook

Una RunBook è una transazione piccola, deterministica, verificabile e
certificata.

Compone Core e Knowledge, verifica le precondizioni, opera nel proprio
perimetro, verifica l'esito e produce un artifact.

### Journal e artifact

Il Journal conserva la cronologia delle transazioni.

Gli artifact conservano sorgente eseguita, log, evidenze e
certificazione.

Né Journal né artifact sostituiscono lo stato canonico corrente.

## Grafo dei moduli

Il grafo deve restare aciclico:

    RunBook
    ├── core.sh
    └── knowledge.sh
        └── continuity.sh
            └── generate_views.py

Vincoli:

- Core non dipende da Knowledge;
- Knowledge deve essere validabile senza dipendere dal Core;
- Continuity appartiene a Knowledge;
- il generatore non governa provider o sistemi remoti;
- nessuna dipendenza circolare è ammessa.

## Contratto di caricamento

I moduli Bash condivisi devono essere:

- source-safe;
- caricabili ripetutamente;
- privi di azioni remote durante il caricamento;
- privi di output indesiderato;
- dotati di responsabilità e dipendenze dichiarate.

## Flusso corrente

    RunBook
    → Core
    → Provider
    → evidenze
    → verifica
    → aggiornamento dello stato
    → Knowledge
    → Journal
    → commit
    → push
    → verifica remota
    → artifact

La documentazione appartiene alla stessa transazione della modifica.

## Continuità fra sessioni

Il punto di ingresso unico è:

`START-HERE.md`

Ogni sessione deve lasciare il repository sufficiente a comprendere:

- missione;
- Costituzione;
- architettura;
- stato corrente;
- roadmap;
- gate successivo;
- divieti;
- Definition of Done.

La sessione corrente è responsabile anche della sessione futura.

## Decisioni V2 approvate

- governo autonomo dell'Habitat;
- runtime deterministico;
- provider indipendenti;
- Knowledge come componente architetturale;
- `STATE.json` come stato progettuale canonico;
- un solo generatore delle viste;
- separazione fra presente e storia;
- documentazione ufficiale come fonte primaria;
- contratti neutrali e implementazioni concrete;
- nessuna AI decisionale.

## Componenti non ancora approvati

Non sono ancora approvati come componenti operativi:

- Nmap;
- PostgreSQL o SQLite;
- registro operativo degli oggetti;
- motore di correlazione;
- gestione definitiva dei secret;
- provider applicativi aggiuntivi;
- interfaccia grafica.

Devono essere valutati mediante fonti ufficiali, alternative,
complessità, ciclo di vita e necessità reale.

## Repository Ready

Una transazione è conclusa quando:

- lo stato corrente è coerente;
- non esiste drift nelle viste;
- esistono un solo entrypoint e un solo gate;
- il repository locale è pulito;
- `HEAD` locale coincide con `origin/main`;
- una nuova sessione può continuare senza la chat precedente.
