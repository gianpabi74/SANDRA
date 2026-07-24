# Next Task

> GENERATED FILE — DO NOT EDIT MANUALLY  
> Source: `STATE.json`

## R3-000014B — Desired State Use Case Foundation Publication

### Tipo

`application_vertical_contract_publication`

### Target

- DesiredStateDeclaration
- DesiredStateRecord
- DeclareDesiredStatePort
- DesiredStateRepository
- DeclareDesiredState
- Application Ports Foundation revision 5
- STATE.json
- Knowledge canonical history

### Target esclusi

- live telemetry
- imperative commands
- adapter configuration
- policy evaluation
- planning
- execution
- remote Habitat
- software installation

### Obiettivi

- verify the exact R3-000014A candidate
- publish immutable Desired State contracts
- preserve approved intent independently from observed state
- enforce monotonic optimistic generation control
- register the use case in canonical STATE

### Divieti

- no unapproved desired intent
- no live telemetry in Desired State
- no imperative command execution
- no adapter-specific configuration
- no policy decision
- no Habitat modification

### Gate successivo

Solo dopo il completamento deterministico del gate corrente:

`R3-000015`
