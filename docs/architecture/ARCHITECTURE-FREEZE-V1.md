# SANDRA Architecture GRANITA Freeze V1

## Stato

**IMMUTABILE FINO ALLA FINE DEL PROGETTO**

La struttura canonica di SANDRA è:

    src/
    ├── core/
    ├── knowledge/
    ├── sandra/
    │   ├── domain/
    │   ├── application/
    │   │   ├── ports/
    │   │   │   ├── inbound/
    │   │   │   └── outbound/
    │   │   └── use_cases/
    │   ├── controllers/
    │   │   └── security/
    │   ├── adapters/
    │   │   ├── inbound/
    │   │   └── outbound/
    │   │       ├── compute/
    │   │       ├── operating_system/
    │   │       ├── backup/
    │   │       ├── network/
    │   │       ├── observability/
    │   │       ├── persistence/
    │   │       ├── policy_engine/
    │   │       └── security/
    │   └── bootstrap/
    ├── tests/
    │   ├── unit/
    │   ├── contract/
    │   └── integration/
    └── runbooks/

## Responsabilità

- `domain`: modello puro e invarianti.
- `application`: porte e casi d'uso.
- `controllers`: reconciliation loop.
- `adapters/inbound`: CLI, timer, eventi, futura API/UI.
- `adapters/outbound`: tecnologie e prodotti concreti.
- `bootstrap`: configurazione e composizione delle dipendenze.
- `tests`: unit, contract e integration.
- `security`: famiglia funzionale permanente.

## Regole immutabili

- Il dominio non importa tecnologie.
- Le tecnologie concrete esistono negli adapter.
- Le policy sono separate dall'enforcement.
- I controller invocano casi d'uso applicativi.
- Il bootstrap non contiene logica decisionale.
- Non verranno ricreati layer `provider`, `providers`, `interfaces`,
  `runtime` o `policy` sotto `src/sandra`.
- OpenVAS/Greenbone sarà un adapter Security, non il decisore.
- La struttura non cambia per preferenza, moda o intuizione.

## Ciclo operativo

    Observe
    → Reconcile
    → Evaluate Policy
    → Plan
    → Execute
    → Verify
    → Record
