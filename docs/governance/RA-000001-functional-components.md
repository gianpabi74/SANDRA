# RA-000001 — Componenti funzionali e generici

## Regola

I componenti di SANDRA devono avere nomi funzionali e generici.

Pipeline canonica:

`intent → decision → policy → execute → provider → verify → remember`

## Responsabilità

- `decision` produce una decisione;
- `policy` autorizza o rifiuta;
- `execute` esegue un comando già autorizzato;
- `provider` traduce il comando nel dominio tecnico;
- `verify` verifica il risultato;
- `remember` registra stato ed evidenze.

## Execute

Esiste un solo componente `execute` generico.

`execute` non sceglie:

- provider;
- oggetto;
- operazione;
- tempi;
- priorità.

Riceve questi dati da una richiesta già autorizzata.

## Provider

Ogni dominio tecnico possiede un provider specifico.

Esempi:

- `pve`;
- `pbs`;
- `linux`;
- `windows`.

I provider implementano una stessa interfaccia funzionale quando la
capability è supportata.

## Pattern adottati

L'architettura utilizza modelli consolidati:

- Ports and Adapters;
- Command;
- Strategy;
- Pipeline;
- Single Responsibility Principle.

Non vengono introdotti livelli ulteriori senza una necessità reale e
dimostrata.
