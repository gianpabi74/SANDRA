# Architecture

## Path canonici

Core installato:

`/opt/sandra/core/core.sh`

Provider operativi:

`/opt/sandra/providers`

Runbook operativi:

`/opt/sandra/runbooks`

Configurazione locale:

`/opt/sandra/config`

Artefatti:

`/opt/sandra/artifacts`

Stato operativo:

`/opt/sandra/state`

Knowledge:

`/opt/sandra/knowledge`

## Componenti

### Core

Gestisce ciclo di vita, lock, log, evidenze, certificazione e artefatto.

### Provider

Governano famiglie di oggetti attraverso interfacce ufficiali. Non
prendono decisioni.

### Runbook

Sono transazioni operative piccole, deterministiche e verificabili.

### State

Contiene la verità operativa dell'Habitat.

### Knowledge

Conserva sorgenti, specifiche, ADR, Journal e stato progettuale.

## Flusso

`Runbook → Provider → Facts → verifica → State → Knowledge → artefatto`
