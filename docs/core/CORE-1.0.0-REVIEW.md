# Core 1.0.0 — Review

## Stato osservato

- Path installato: `/opt/sandra/core/core.sh`
- Versione: `1.0.0`
- SHA-256: `fff13ef5c33b2112f837362a17df29fd612bc8206c224660c41738ac7629f8c5`
- Sintassi Bash: `PASS`
- Caricamento con source: `PASS`
- Proprietario e permessi: `root:root 644`

## API osservata

`sandra_log,sandra_require_command sandra_require_file,sandra_assert sandra_capture,sandra_begin sandra_finalize,sandra_end sandra_fail`

## Responsabilità attuali

Il Core gestisce:

- modalità Bash rigorosa;
- identificazione univoca dei run;
- lock esclusivo;
- log ed evidenze;
- certificazione;
- creazione dell'artefatto;
- export verificato verso il Mac.

## Gap oggettivi da correggere in 1.1.0

1. includere nell'artefatto il runbook realmente eseguito;
2. registrare file, funzione e riga esatta degli errori;
3. correggere definitivamente la gestione dello stato finale;
4. separare export e sincronizzazione Knowledge dal ciclo vitale minimo;
5. conservare compatibilità con l'API pubblica esistente;
6. aggiungere self-test prima dell'installazione;
7. installare la nuova versione solo dopo verifica e rollback locale disponibile.

## Decisione

Il Core 1.0.0 resta operativo fino alla certificazione del Core 1.1.0.
Nessun provider sarà creato prima del completamento di tale aggiornamento.
