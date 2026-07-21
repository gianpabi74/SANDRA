# SANDRA — Architettura corrente

## Pipeline canonica

```text
decision
  ↓
policy
  ↓
execute
  ↓
provider
  ↓
verify
  ↓
remember
  ↓
knowledge
```

## Componenti trasversali

- `core`: primitive comuni, run, assert, errori ed evidenze
- `config`: configurazione non segreta
- `habitat`: rappresentazione degli ambienti reali
- `report`: report da Habitat, Verify e Knowledge senza modificare sistemi
- `docker`: strumenti e servizi containerizzati futuri
- `artifacts`: log, JSON, hash ed evidenze dei run

## Regole operative

1. Ogni Bash importa `/opt/sandra/core/core.sh`.
2. Ogni Bash importa `/opt/sandra/knowledge/knowledge.sh`.
3. Execute non decide.
4. Policy restituisce `ALLOW` oppure `DENY`.
5. Provider traduce operazioni nel dominio tecnico.
6. Verify verifica e non modifica sistemi.
7. Remember registra fatti verificati.
8. Report non modifica sistemi.
9. Non si creano nuove directory top-level.
10. Ogni cambiamento deve essere deterministico e certificato.
