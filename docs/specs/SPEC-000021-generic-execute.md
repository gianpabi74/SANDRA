# SPEC-000021 — Execute generico

## Stato

Certified PASS.

## Percorso canonico

`/opt/sandra/execute/execute.sh`

## Versione

`1.0.0`

## Funzione

`execute_run REQUEST_FILE`

## Contratto della richiesta

La richiesta utilizza lo schema:

`sandra.execute.request.v1`

Campi obbligatori:

- `provider`;
- `decision`;
- `operation`;
- `object_id`.

## Responsabilità

`execute`:

1. valida la struttura della richiesta;
2. accetta esclusivamente `decision = ALLOW`;
3. individua il provider richiesto;
4. carica il provider in un processo Bash isolato;
5. invoca `provider_<operation>`;
6. restituisce un risultato normalizzato.

## Risultato

Il risultato utilizza:

`sandra.execute.result.v1`

e conserva l'esito originale del provider in:

`provider_result`

## Isolamento

Ogni provider viene caricato in un processo Bash distinto.

Questo impedisce collisioni tra provider che esportano la stessa
interfaccia `provider_*`.

## Divieti

`execute` non:

- sceglie il provider;
- sceglie l'oggetto;
- sceglie l'operazione;
- produce o modifica decisioni;
- interpreta policy o Habitat.

## Provider certificati

- `pve`

## Componenti rimossi

- `/opt/sandra/execute/proxmox_execute.sh`
- `/opt/sandra/provider/proxmox/`

Il provider canonico PVE resta:

`/opt/sandra/provider/pve/provider.sh`
