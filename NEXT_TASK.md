# Next Task

> GENERATED FILE — DO NOT EDIT MANUALLY  
> Source: `STATE.json`

## R3-000009 — Canonical Domain Migration

### Tipo

`canonical_source_migration`

### Target

- src/sandra/domain/governance
- tests/unit/domain
- Knowledge canonica

### Target esclusi

- sistemi remoti dell'Habitat
- src/domain removal
- src/runtime removal
- software installation

### Obiettivi

- publish certified domain under canonical source root
- publish portable domain unit tests
- prove byte identity with certified source
- preserve historical migration sources
- preserve Architecture GRANITA Freeze

### Divieti

- no source deletion
- no behavior modification
- no dependency addition
- no Habitat modification
- no architecture change
- no intuitive correction

### Gate successivo

Solo dopo il completamento deterministico del gate corrente:

`R3-000010`
