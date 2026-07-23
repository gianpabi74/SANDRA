# Next Task

> GENERATED FILE — DO NOT EDIT MANUALLY  
> Source: `STATE.json`

## R3-000010 — Application Ports Foundation

### Tipo

`application_contract_foundation`

### Target

- src/sandra/application
- tests/contract/application
- docs/contracts/application/APPLICATION-PORTS-FOUNDATION-V1.json
- STATE.json

### Target esclusi

- concrete use cases
- controllers
- outbound adapters
- remote Habitat
- software installation

### Obiettivi

- establish technology-independent application messages
- establish inbound command and query ports
- establish outbound persistence event and unit-of-work ports
- certify dependency direction

### Divieti

- no product-specific application contract
- no controller dependency
- no adapter dependency
- no bootstrap dependency
- no Habitat modification
- no software installation

### Gate successivo

Solo dopo il completamento deterministico del gate corrente:

`R3-000011`
