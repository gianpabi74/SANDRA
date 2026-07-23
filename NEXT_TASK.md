# Next Task

> GENERATED FILE — DO NOT EDIT MANUALLY  
> Source: `STATE.json`

## R3-000009D — Constitutional Operational Contracts

### Tipo

`constitutional_contract_registration`

### Target

- Resource Lifecycle Contract V1
- Evidence Authority Contract V1
- Reconciliation Concurrency Contract V1
- Execution Safety Contract V1
- STATE.json

### Target esclusi

- domain implementation
- application implementation
- controller implementation
- adapter implementation
- remote Habitat
- software installation

### Obiettivi

- define immutable operational invariants
- prevent stale or concurrent mutation
- prevent unqualified evidence promotion
- require safe and verifiable execution

### Divieti

- no architecture changes
- no product-specific exceptions
- no Habitat modifications
- no software installation

### Gate successivo

Solo dopo il completamento deterministico del gate corrente:

`R3-000009E`
