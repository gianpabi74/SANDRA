# Start Here

Indice generato automaticamente dal modulo Knowledge.

Generato UTC: 2026-07-21T16:47:01Z

## Ordine di lettura

10. [Repository Overview](README.md)
20. [Project Charter](PROJECT_CHARTER.md)
30. [Current Architecture](ARCHITECTURE.md)
40. [Current State](CURRENT_STATE.md)
50. [Next Task](NEXT_TASK.md)
60. [Project Roadmap](ROADMAP.md)

## Documentazione canonica

### Constitution

Owner: `governance`  
Path: `docs/constitution`

- [Costituzione — Scheletro canonico SANDRA](docs/constitution/CANONICAL-SKELETON.md)

### Architecture

Owner: `architecture`  
Path: `docs/architecture`

- [SANDRA — Architettura corrente](docs/architecture/CURRENT-ARCHITECTURE.md)

### Engineering Standards

Owner: `engineering`  
Path: `docs/engineering`

_Nessun documento pubblicato._

### Specifications

Owner: `architecture`  
Path: `docs/specs`

- [SPEC-000001 — Runtime Core Contract](docs/specs/SPEC-000001-runtime-core-installation.md)
- [SPEC-000001 — Runtime Core Contract](docs/specs/SPEC-000001-runtime-core.md)
- [SPEC-000002 — Knowledge Contract](docs/specs/SPEC-000002-knowledge.md)
- [SPEC-000003 — Knowledge Synchronization Contract](docs/specs/SPEC-000003-knowledge-synchronization.md)
- [SPEC-000004 — Knowledge Manifest](docs/specs/SPEC-000004-knowledge-manifest.md)
- [SPEC-000005 — Knowledge Canonical Module](docs/specs/SPEC-000005-knowledge-module.md)
- [SPEC-000009 — Proxmox Version Capability](docs/specs/SPEC-000009-proxmox-version.md)
- [SPEC-000010 — Proxmox Nodes Capability](docs/specs/SPEC-000010-proxmox-nodes.md)
- [SPEC-000011 — Proxmox Resources Capability](docs/specs/SPEC-000011-proxmox-resources.md)
- [SPEC-000012 — Proxmox QEMU VM Capability](docs/specs/SPEC-000012-proxmox-vms.md)
- [SPEC-000013 — Proxmox LXC Containers Capability](docs/specs/SPEC-000013-proxmox-containers.md)
- [SPEC-000014 — Proxmox Storage Capability](docs/specs/SPEC-000014-proxmox-storage.md)
- [SPEC-000015 — Proxmox Habitat](docs/specs/SPEC-000015-proxmox-habitat.md)
- [SPEC-000016 — Proxmox Operational Policy](docs/specs/SPEC-000016-proxmox-policy.md)
- [SPEC-000017 — Proxmox Policy Validator](docs/specs/SPEC-000017-proxmox-policy-validator.md)
- [SPEC-000018 — Proxmox Start Capability](docs/specs/SPEC-000018-proxmox-start.md)
- [SPEC-000019 — Proxmox Execute](docs/specs/SPEC-000019-proxmox-execute.md)
- [SPEC-000020 — Provider PVE](docs/specs/SPEC-000020-pve-provider.md)
- [SPEC-000021 — Execute generico](docs/specs/SPEC-000021-generic-execute.md)
- [SPEC-000022 — Provider PBS](docs/specs/SPEC-000022-pbs-provider.md)

### Architecture Decisions

Owner: `governance`  
Path: `docs/adr`

- [ADR-000001 — Separazione tra Runtime e Knowledge](docs/adr/ADR-000001-knowledge-separation.md)

### Design Decisions

Owner: `architecture`  
Path: `docs/decisions`

_Nessun documento pubblicato._

### Strategic Roadmap

Owner: `governance`  
Path: `docs/roadmap`

- [SANDRA — Roadmap](docs/roadmap/ROADMAP.md)

### Official Glossary

Owner: `governance`  
Path: `docs/glossary`

_Nessun documento pubblicato._

## Regola di pubblicazione

1. Inserire il documento nella directory canonica.
2. Eseguire `knowledge_generate_index`.
3. Eseguire `knowledge_validate`.
4. Eseguire `knowledge_sync "messaggio commit"`.

Non modificare manualmente questo indice.
