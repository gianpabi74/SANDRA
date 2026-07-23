# Next Task

> GENERATED FILE — DO NOT EDIT MANUALLY  
> Source: `STATE.json`

## R3-000009F — Canonical Domain Purification

### Tipo

`domain_boundary_enforcement`

### Target

- src/sandra/domain/governance
- src/sandra/adapters/inbound/governance_resource_cli
- STATE.json
- Knowledge canonical history

### Target esclusi

- legacy src/domain
- legacy src/runtime
- application implementation
- controller implementation
- outbound adapter implementation
- remote Habitat
- software installation

### Obiettivi

- remove CLI responsibility from canonical domain
- create the canonical inbound CLI adapter
- preserve externally observable CLI behavior
- certify the inward dependency direction

### Divieti

- no domain behavior change
- no legacy source deletion
- no architecture change
- no Habitat modification
- no software installation

### Gate successivo

Solo dopo il completamento deterministico del gate corrente:

`R3-000010`
