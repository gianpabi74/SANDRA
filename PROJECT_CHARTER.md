# Project Charter

## Missione

Mantenere l'equilibrio dell'Habitat.

## Principi immutabili

- runtime deterministico;
- una sola verità canonica;
- un solo owner per responsabilità;
- software libero maturo prima di codice interno;
- nessuna complessità priva di valore operativo;
- ogni modifica deve essere verificata;
- ogni Bash deve produrre un artefatto `.tar.gz`;
- ogni avanzamento deve essere documentato ed esplorabile;
- nessun secret nella Knowledge o su Git.

## Separazione permanente

- chi osserva non decide;
- chi decide non esegue;
- chi esegue non verifica;
- chi verifica non modifica;
- chi ricorda non reinventa la verità.

## Definition of Done dei Runbook

Un Runbook SANDRA è concluso esclusivamente quando:

- la modifica tecnica è stata eseguita;
- il risultato reale è stato verificato;
- la Knowledge pertinente è stata aggiornata;
- il Journal del run è stato scritto;
- `CURRENT_STATE.md` riflette lo stato reale, quando applicabile;
- `NEXT_TASK.md` identifica un solo tassello successivo;
- le modifiche sono state committate;
- il push verso il remoto è stato eseguito e verificato;
- l'artefatto `.tar.gz` è stato creato, esportato e verificato.

La documentazione non è un'attività successiva al Runbook: è parte
obbligatoria della stessa transazione ingegneristica.
