# Core 1.1.0

## Scopo

Libreria comune caricata da ogni runbook mediante:

`source /opt/sandra/core/core.sh`

## Funzioni comuni

- modalità Bash rigorosa e umask;
- lock esclusivo;
- identificazione del run;
- log ed evidenze;
- asserzioni e prerequisiti;
- diagnostica file, funzione, riga e comando;
- certificazione;
- artefatto univoco;
- export al Mac;
- verifica dimensione e SHA-256.

## Compatibilità

L'API pubblica della versione 1.0.0 è preservata.

## Runbook nell'artefatto

Quando un runbook è eseguito da file, il Core include automaticamente
la copia esatta come `runbook.sh`.

Per i blocchi eseguiti direttamente da standard input viene registrato
`runbook-source.txt`.
