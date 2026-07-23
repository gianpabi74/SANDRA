#!/usr/bin/env bash

source /opt/sandra/core/core.sh
source /opt/sandra/knowledge/knowledge.sh

set -Eeuo pipefail
umask 077

export SANDRA_RUNBOOK_SOURCE="/root/R3-000002A-object-evidence-model.sh"

sandra_begin \
    "R3-000002A" \
    "Register Object and Evidence Model"

for command_name in python3 git install cp sha256sum; do
    sandra_require_command "${command_name}"
done

ROOT="${SANDRA_KNOWLEDGE_ROOT}"
STATE="${ROOT}/STATE.json"
SPEC_ROOT="${ROOT}/docs/specs/governance-model"
SCHEMA_ROOT="${SPEC_ROOT}/schemas"
EXAMPLE_ROOT="${SPEC_ROOT}/examples"
BACKUP_ROOT="${SANDRA_RUN_DIR}/backups"
JOURNAL="$(knowledge_journal_path)"
RUNBOOK_DEST="${ROOT}/src/runbooks/${SANDRA_RUNBOOK_ID}.sh"

TARGET_FILES=(
    "${STATE}"
    "${SPEC_ROOT}/OBJECT-AND-EVIDENCE-MODEL.md"
    "${SCHEMA_ROOT}/managed-object.schema.json"
    "${SCHEMA_ROOT}/observation.schema.json"
    "${SCHEMA_ROOT}/evidence.schema.json"
    "${SCHEMA_ROOT}/relationship.schema.json"
    "${EXAMPLE_ROOT}/managed-object.example.json"
    "${EXAMPLE_ROOT}/observation.example.json"
    "${EXAMPLE_ROOT}/evidence.example.json"
    "${EXAMPLE_ROOT}/relationship.example.json"
)

sandra_require_file "${STATE}"
sandra_require_file "${ROOT}/manifest/KNOWLEDGE_MANIFEST.json"

install -d -m 0700 "${BACKUP_ROOT}"

for target_file in "${TARGET_FILES[@]}"; do
    if [[ -f "${target_file}" ]]; then
        relative="${target_file#${ROOT}/}"
        backup_path="${BACKUP_ROOT}/${relative}"
        install -d -m 0700 "$(dirname "${backup_path}")"
        cp -a -- "${target_file}" "${backup_path}"
    fi
done

install -d -m 0755 \
    "${SPEC_ROOT}" \
    "${SCHEMA_ROOT}" \
    "${EXAMPLE_ROOT}" \
    "$(dirname "${JOURNAL}")"

install -m 0600 \
    "${SANDRA_RUNBOOK_SOURCE}" \
    "${RUNBOOK_DEST}"

cat > "${SPEC_ROOT}/OBJECT-AND-EVIDENCE-MODEL.md" <<'EOF'
# Object and Evidence Model

## Stato

Canonical V1.

## Modelli di riferimento

- Kubernetes API conventions:
  `apiVersion`, `kind`, `metadata`, `spec`, `status`.
- OpenTelemetry semantic conventions:
  attributi coerenti e portabili per risorse e osservazioni.
- JSON Schema Draft 2020-12:
  validazione deterministica dei documenti.
- CloudEvents:
  riferimento futuro per l'envelope degli eventi operativi.

## Managed Object

Un Managed Object rappresenta un'entità persistente dell'ambiente gestito.

Campi obbligatori:

- `apiVersion`
- `kind`
- `metadata`
- `spec`
- `status`

### metadata

Contiene identità amministrativa stabile:

- `id`: identificatore immutabile generato dal sistema;
- `name`: nome leggibile;
- `labels`: classificazioni usate dalle policy;
- `annotations`: metadati non selettivi;
- `createdAt`;
- `updatedAt`.

### spec

Contiene stato governato e dichiarazioni autorizzate:

- classificazioni;
- ruoli;
- protection profile;
- identità dichiarate;
- capability richieste;
- policy binding.

### status

Contiene stato osservato e derivato:

- lifecycle phase;
- technology identification;
- capability disponibili;
- condizioni;
- latest observation;
- reconciliation revision.

`spec` non viene popolato automaticamente da una singola osservazione.

`status` non modifica autonomamente `spec`.

## Observation

Una Observation è un fatto raccolto da una fonte.

Non contiene decisioni.

Proprietà minime:

- soggetto osservato;
- fonte;
- istante;
- attributo;
- valore;
- unità, se applicabile;
- qualità;
- riferimento al dato grezzo.

## Evidence

Evidence collega una o più osservazioni a:

- provenienza;
- integrità;
- metodo di acquisizione;
- timestamp;
- classificazione di autorevolezza.

Livelli iniziali:

- `authoritative`
- `corroborated`
- `candidate`
- `conflicting`

Nmap produce normalmente evidenza `candidate`.

Un'API ufficiale autenticata può produrre evidenza `authoritative`
nel proprio ambito documentato.

## Relationship

Una Relationship collega due Managed Object.

Tipi iniziali:

- `hostedOn`
- `dependsOn`
- `managedBy`
- `protectedBy`
- `backedUpBy`
- `resolvesThrough`
- `peerOf`
- `provides`
- `consumes`

Le relazioni devono avere evidenze e validità temporale.

## Regole

- nessuna identità viene confermata da un solo segnale debole;
- indirizzo IP, hostname e MAC non sono identificatori universali;
- dati osservati e stato governato restano separati;
- ogni modifica autonoma deve riferirsi a un object ID stabile;
- ogni decisione deve indicare le evidenze utilizzate;
- conflitti fra fonti impediscono l'azione finché la policy non li risolve;
- nomi di prodotto non entrano nel nucleo del dominio.
EOF

cat > "${SCHEMA_ROOT}/managed-object.schema.json" <<'EOF'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://sandra.local/schemas/managed-object.schema.json",
  "title": "ManagedObject",
  "type": "object",
  "additionalProperties": false,
  "required": [
    "apiVersion",
    "kind",
    "metadata",
    "spec",
    "status"
  ],
  "properties": {
    "apiVersion": {
      "const": "governance.sandra.io/v1"
    },
    "kind": {
      "const": "ManagedObject"
    },
    "metadata": {
      "type": "object",
      "additionalProperties": false,
      "required": [
        "id",
        "name",
        "labels",
        "annotations",
        "createdAt",
        "updatedAt"
      ],
      "properties": {
        "id": {
          "type": "string",
          "pattern": "^obj_[a-z0-9]{16,64}$"
        },
        "name": {
          "type": "string",
          "minLength": 1
        },
        "labels": {
          "type": "object",
          "additionalProperties": {
            "type": "string"
          }
        },
        "annotations": {
          "type": "object",
          "additionalProperties": {
            "type": "string"
          }
        },
        "createdAt": {
          "type": "string",
          "format": "date-time"
        },
        "updatedAt": {
          "type": "string",
          "format": "date-time"
        }
      }
    },
    "spec": {
      "type": "object",
      "additionalProperties": false,
      "required": [
        "classifications",
        "roles",
        "protectionProfile",
        "declaredIdentifiers",
        "requiredCapabilities",
        "policyBindings"
      ],
      "properties": {
        "classifications": {
          "type": "array",
          "items": {
            "type": "string",
            "minLength": 1
          },
          "uniqueItems": true
        },
        "roles": {
          "type": "array",
          "items": {
            "type": "string",
            "minLength": 1
          },
          "uniqueItems": true
        },
        "protectionProfile": {
          "enum": [
            "protected",
            "critical",
            "standard",
            "disposable"
          ]
        },
        "declaredIdentifiers": {
          "type": "array",
          "items": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "scheme",
              "value",
              "authority"
            ],
            "properties": {
              "scheme": {
                "type": "string",
                "minLength": 1
              },
              "value": {
                "type": "string",
                "minLength": 1
              },
              "authority": {
                "enum": [
                  "declared",
                  "authoritative",
                  "candidate"
                ]
              }
            }
          }
        },
        "requiredCapabilities": {
          "type": "array",
          "items": {
            "type": "string",
            "pattern": "^[a-z][a-z0-9]*(\\.[a-z][a-z0-9_]*)+$"
          },
          "uniqueItems": true
        },
        "policyBindings": {
          "type": "array",
          "items": {
            "type": "string",
            "minLength": 1
          },
          "uniqueItems": true
        }
      }
    },
    "status": {
      "type": "object",
      "additionalProperties": false,
      "required": [
        "phase",
        "technology",
        "availableCapabilities",
        "conditions",
        "latestObservationAt",
        "reconciliationRevision"
      ],
      "properties": {
        "phase": {
          "enum": [
            "unknown",
            "candidate",
            "active",
            "degraded",
            "conflicting",
            "unsupported",
            "retired"
          ]
        },
        "technology": {
          "type": "object",
          "additionalProperties": false,
          "required": [
            "id",
            "status",
            "evidenceIds"
          ],
          "properties": {
            "id": {
              "type": [
                "string",
                "null"
              ]
            },
            "status": {
              "enum": [
                "unknown",
                "candidate",
                "confirmed",
                "conflicting",
                "unsupported"
              ]
            },
            "evidenceIds": {
              "type": "array",
              "items": {
                "type": "string"
              },
              "uniqueItems": true
            }
          }
        },
        "availableCapabilities": {
          "type": "array",
          "items": {
            "type": "string"
          },
          "uniqueItems": true
        },
        "conditions": {
          "type": "array",
          "items": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "type",
              "status",
              "reason",
              "observedAt"
            ],
            "properties": {
              "type": {
                "type": "string"
              },
              "status": {
                "enum": [
                  "true",
                  "false",
                  "unknown"
                ]
              },
              "reason": {
                "type": "string"
              },
              "observedAt": {
                "type": "string",
                "format": "date-time"
              }
            }
          }
        },
        "latestObservationAt": {
          "type": [
            "string",
            "null"
          ],
          "format": "date-time"
        },
        "reconciliationRevision": {
          "type": "integer",
          "minimum": 0
        }
      }
    }
  }
}
EOF

cat > "${SCHEMA_ROOT}/observation.schema.json" <<'EOF'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://sandra.local/schemas/observation.schema.json",
  "title": "Observation",
  "type": "object",
  "additionalProperties": false,
  "required": [
    "apiVersion",
    "kind",
    "metadata",
    "subjectRef",
    "source",
    "observedAt",
    "attribute",
    "value",
    "quality",
    "rawArtifactRef"
  ],
  "properties": {
    "apiVersion": {
      "const": "governance.sandra.io/v1"
    },
    "kind": {
      "const": "Observation"
    },
    "metadata": {
      "type": "object",
      "required": [
        "id"
      ],
      "properties": {
        "id": {
          "type": "string",
          "pattern": "^obs_[a-z0-9]{16,64}$"
        }
      },
      "additionalProperties": false
    },
    "subjectRef": {
      "type": "string",
      "pattern": "^obj_[a-z0-9]{16,64}$"
    },
    "source": {
      "type": "object",
      "additionalProperties": false,
      "required": [
        "adapter",
        "tool",
        "version",
        "method"
      ],
      "properties": {
        "adapter": {
          "type": "string"
        },
        "tool": {
          "type": "string"
        },
        "version": {
          "type": "string"
        },
        "method": {
          "type": "string"
        }
      }
    },
    "observedAt": {
      "type": "string",
      "format": "date-time"
    },
    "attribute": {
      "type": "string",
      "minLength": 1
    },
    "value": {},
    "unit": {
      "type": [
        "string",
        "null"
      ]
    },
    "quality": {
      "enum": [
        "authoritative",
        "corroborated",
        "candidate",
        "conflicting"
      ]
    },
    "rawArtifactRef": {
      "type": [
        "string",
        "null"
      ]
    }
  }
}
EOF

cat > "${SCHEMA_ROOT}/evidence.schema.json" <<'EOF'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://sandra.local/schemas/evidence.schema.json",
  "title": "Evidence",
  "type": "object",
  "additionalProperties": false,
  "required": [
    "apiVersion",
    "kind",
    "metadata",
    "subjectRef",
    "observationRefs",
    "authority",
    "provenance",
    "integrity",
    "capturedAt"
  ],
  "properties": {
    "apiVersion": {
      "const": "governance.sandra.io/v1"
    },
    "kind": {
      "const": "Evidence"
    },
    "metadata": {
      "type": "object",
      "required": [
        "id"
      ],
      "properties": {
        "id": {
          "type": "string",
          "pattern": "^evd_[a-z0-9]{16,64}$"
        }
      },
      "additionalProperties": false
    },
    "subjectRef": {
      "type": "string",
      "pattern": "^obj_[a-z0-9]{16,64}$"
    },
    "observationRefs": {
      "type": "array",
      "items": {
        "type": "string",
        "pattern": "^obs_[a-z0-9]{16,64}$"
      },
      "minItems": 1,
      "uniqueItems": true
    },
    "authority": {
      "enum": [
        "authoritative",
        "corroborated",
        "candidate",
        "conflicting"
      ]
    },
    "provenance": {
      "type": "object",
      "additionalProperties": false,
      "required": [
        "collector",
        "interface",
        "authenticated"
      ],
      "properties": {
        "collector": {
          "type": "string"
        },
        "interface": {
          "type": "string"
        },
        "authenticated": {
          "type": "boolean"
        }
      }
    },
    "integrity": {
      "type": "object",
      "additionalProperties": false,
      "required": [
        "algorithm",
        "digest"
      ],
      "properties": {
        "algorithm": {
          "const": "sha256"
        },
        "digest": {
          "type": "string",
          "pattern": "^[a-f0-9]{64}$"
        }
      }
    },
    "capturedAt": {
      "type": "string",
      "format": "date-time"
    }
  }
}
EOF

cat > "${SCHEMA_ROOT}/relationship.schema.json" <<'EOF'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://sandra.local/schemas/relationship.schema.json",
  "title": "Relationship",
  "type": "object",
  "additionalProperties": false,
  "required": [
    "apiVersion",
    "kind",
    "metadata",
    "sourceRef",
    "type",
    "targetRef",
    "evidenceRefs",
    "validFrom",
    "validUntil"
  ],
  "properties": {
    "apiVersion": {
      "const": "governance.sandra.io/v1"
    },
    "kind": {
      "const": "Relationship"
    },
    "metadata": {
      "type": "object",
      "required": [
        "id"
      ],
      "properties": {
        "id": {
          "type": "string",
          "pattern": "^rel_[a-z0-9]{16,64}$"
        }
      },
      "additionalProperties": false
    },
    "sourceRef": {
      "type": "string",
      "pattern": "^obj_[a-z0-9]{16,64}$"
    },
    "type": {
      "enum": [
        "hostedOn",
        "dependsOn",
        "managedBy",
        "protectedBy",
        "backedUpBy",
        "resolvesThrough",
        "peerOf",
        "provides",
        "consumes"
      ]
    },
    "targetRef": {
      "type": "string",
      "pattern": "^obj_[a-z0-9]{16,64}$"
    },
    "evidenceRefs": {
      "type": "array",
      "items": {
        "type": "string",
        "pattern": "^evd_[a-z0-9]{16,64}$"
      },
      "minItems": 1,
      "uniqueItems": true
    },
    "validFrom": {
      "type": "string",
      "format": "date-time"
    },
    "validUntil": {
      "type": [
        "string",
        "null"
      ],
      "format": "date-time"
    }
  }
}
EOF

cat > "${EXAMPLE_ROOT}/managed-object.example.json" <<'EOF'
{
  "apiVersion": "governance.sandra.io/v1",
  "kind": "ManagedObject",
  "metadata": {
    "id": "obj_01k0example000001",
    "name": "example-workload",
    "labels": {
      "environment": "managed",
      "class": "compute-workload"
    },
    "annotations": {},
    "createdAt": "2026-07-23T12:30:00Z",
    "updatedAt": "2026-07-23T12:30:00Z"
  },
  "spec": {
    "classifications": [
      "compute",
      "virtual"
    ],
    "roles": [
      "application-workload"
    ],
    "protectionProfile": "standard",
    "declaredIdentifiers": [
      {
        "scheme": "administrative-name",
        "value": "example-workload",
        "authority": "declared"
      }
    ],
    "requiredCapabilities": [
      "compute.state.read"
    ],
    "policyBindings": []
  },
  "status": {
    "phase": "candidate",
    "technology": {
      "id": null,
      "status": "unknown",
      "evidenceIds": []
    },
    "availableCapabilities": [],
    "conditions": [],
    "latestObservationAt": null,
    "reconciliationRevision": 0
  }
}
EOF

cat > "${EXAMPLE_ROOT}/observation.example.json" <<'EOF'
{
  "apiVersion": "governance.sandra.io/v1",
  "kind": "Observation",
  "metadata": {
    "id": "obs_01k0example000001"
  },
  "subjectRef": "obj_01k0example000001",
  "source": {
    "adapter": "linux",
    "tool": "openssh",
    "version": "unknown",
    "method": "authenticated-command"
  },
  "observedAt": "2026-07-23T12:31:00Z",
  "attribute": "system.memory.available",
  "value": 4096,
  "unit": "MiBy",
  "quality": "authoritative",
  "rawArtifactRef": "artifact://example/memory.txt"
}
EOF

cat > "${EXAMPLE_ROOT}/evidence.example.json" <<'EOF'
{
  "apiVersion": "governance.sandra.io/v1",
  "kind": "Evidence",
  "metadata": {
    "id": "evd_01k0example000001"
  },
  "subjectRef": "obj_01k0example000001",
  "observationRefs": [
    "obs_01k0example000001"
  ],
  "authority": "authoritative",
  "provenance": {
    "collector": "linux",
    "interface": "openssh",
    "authenticated": true
  },
  "integrity": {
    "algorithm": "sha256",
    "digest": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  },
  "capturedAt": "2026-07-23T12:31:01Z"
}
EOF

cat > "${EXAMPLE_ROOT}/relationship.example.json" <<'EOF'
{
  "apiVersion": "governance.sandra.io/v1",
  "kind": "Relationship",
  "metadata": {
    "id": "rel_01k0example000001"
  },
  "sourceRef": "obj_01k0example000001",
  "type": "hostedOn",
  "targetRef": "obj_01k0example000002",
  "evidenceRefs": [
    "evd_01k0example000001"
  ],
  "validFrom": "2026-07-23T12:31:01Z",
  "validUntil": null
}
EOF

python3 - \
    "${SCHEMA_ROOT}" \
    "${EXAMPLE_ROOT}" <<'PYTHON'
import json
import pathlib
import re
import sys

schema_root = pathlib.Path(sys.argv[1])
example_root = pathlib.Path(sys.argv[2])

for path in sorted(schema_root.glob("*.json")):
    document = json.loads(path.read_text(encoding="utf-8"))
    if document.get("$schema") != (
        "https://json-schema.org/draft/2020-12/schema"
    ):
        raise SystemExit(f"SCHEMA_DRAFT_INVALID:{path}")
    if document.get("type") != "object":
        raise SystemExit(f"SCHEMA_ROOT_TYPE_INVALID:{path}")

for path in sorted(example_root.glob("*.json")):
    document = json.loads(path.read_text(encoding="utf-8"))
    for field in ("apiVersion", "kind"):
        if field not in document:
            raise SystemExit(
                f"EXAMPLE_FIELD_MISSING:{path}:{field}"
            )

object_document = json.loads(
    (example_root / "managed-object.example.json")
    .read_text(encoding="utf-8")
)

if set(object_document) != {
    "apiVersion",
    "kind",
    "metadata",
    "spec",
    "status",
}:
    raise SystemExit("MANAGED_OBJECT_ENVELOPE_INVALID")

id_patterns = {
    "ManagedObject": r"^obj_[a-z0-9]{16,64}$",
    "Observation": r"^obs_[a-z0-9]{16,64}$",
    "Evidence": r"^evd_[a-z0-9]{16,64}$",
    "Relationship": r"^rel_[a-z0-9]{16,64}$",
}

for path in sorted(example_root.glob("*.json")):
    document = json.loads(path.read_text(encoding="utf-8"))
    pattern = id_patterns[document["kind"]]
    identifier = document["metadata"]["id"]
    if not re.fullmatch(pattern, identifier):
        raise SystemExit(
            f"EXAMPLE_ID_INVALID:{path}:{identifier}"
        )

print("OBJECT_EVIDENCE_MODEL_VALIDATION=PASS")
PYTHON

cat > "${ROOT}/docs/adr/ADR-0005-OBJECT-RESOURCE-ENVELOPE.md" <<'EOF'
# ADR-0005 — Object resource envelope

## Stato

Accepted.

## Decisione

Le risorse canoniche usano:

- `apiVersion`
- `kind`
- `metadata`
- `spec`
- `status`

La separazione deriva dalle Kubernetes API conventions.

OpenTelemetry semantic conventions orientano il vocabolario degli attributi
osservati, senza obbligare SANDRA ad adottare l'intero stack OpenTelemetry.

JSON Schema Draft 2020-12 definisce i contratti machine-readable.

## Fonti ufficiali

- https://kubernetes.io/docs/concepts/overview/working-with-objects/
- https://kubernetes.io/docs/reference/using-api/api-concepts/
- https://opentelemetry.io/docs/concepts/semantic-conventions/
- https://json-schema.org/draft/2020-12
EOF

install -d -m 0755 "$(dirname "${JOURNAL}")"

cat > "${JOURNAL}" <<EOF
# ${SANDRA_RUNBOOK_ID} — Object and Evidence Model

- Run ID: \`${SANDRA_RUN_ID}\`
- Modifiche remote all'Habitat: \`NONE\`
- Nuovi software installati: \`NONE\`

## Risultato

- definito Managed Object;
- definita separazione metadata/spec/status;
- definiti Observation, Evidence e Relationship;
- aggiunti schemi JSON Schema Draft 2020-12;
- aggiunti esempi validati;
- registrato ADR-0005.
EOF

python3 - \
    "${STATE}" \
    "${SANDRA_RUNBOOK_ID}" \
    "${SANDRA_RUN_ID}" \
    "${JOURNAL#${ROOT}/}" <<'PYTHON'
import datetime
import json
import pathlib
import sys

state_path = pathlib.Path(sys.argv[1])
runbook_id = sys.argv[2]
run_id = sys.argv[3]
journal = sys.argv[4]

state = json.loads(state_path.read_text(encoding="utf-8"))

current_gate = (
    state["spec"]["roadmap"]["current_gate"]["runbook"]
)

if current_gate not in {
    "R3-000001",
    "R3-000002",
}:
    raise SystemExit(
        f"STATE_UNEXPECTED_CURRENT_GATE:{current_gate}"
    )

state["metadata"]["state_version"] = "3.1.0"
state["metadata"]["updated_utc"] = (
    datetime.datetime.now(datetime.timezone.utc)
    .replace(microsecond=0)
    .isoformat()
    .replace("+00:00", "Z")
)

state["spec"]["architecture"] = {
    "version": "3.1.0",
    "document": "ARCHITECTURE.md",
    "model": "controller_reconciliation",
    "resource_envelope": "kubernetes_api_conventions",
    "semantic_attributes": "opentelemetry_guided",
    "schema_standard": "json_schema_2020_12",
}

state["spec"]["roadmap"]["current_gate"] = {
    "runbook": "R3-000002",
    "title": "Object and Evidence Model",
    "type": "domain_contract",
    "targets": [
        "Knowledge canonica",
        "schemi del dominio",
    ],
    "excluded_targets": [
        "sistemi remoti dell'Habitat",
        "runtime operativa",
    ],
    "objectives": [
        "definire Managed Object",
        "separare spec e status",
        "definire Observation",
        "definire Evidence",
        "definire Relationship",
        "fornire schemi machine-readable",
    ],
    "prohibitions": [
        "nessuna modifica remota",
        "nessuna installazione software",
        "nessuna identità derivata da un solo segnale debole",
        "nessuna correzione ad intuito",
    ],
}

state["spec"]["roadmap"]["next_gate"] = {
    "runbook": "R3-000003",
    "title": "Capability and Policy Contract",
    "status": "blocked",
}

state["status"]["current_certification"] = {
    "runbook": runbook_id,
    "run_id": run_id,
    "journal": journal,
}

state["status"]["roadmap"] = {
    "phase": "Object and Evidence Model",
    "current_gate": "R3-000002",
    "current_gate_status": "complete",
    "next_gate": "R3-000003",
}

state["status"]["object_evidence_model_v1"] = {
    "runbook": runbook_id,
    "run_id": run_id,
    "status": "certified",
    "managed_object": "defined",
    "observation": "defined",
    "evidence": "defined",
    "relationship": "defined",
    "schemas": "json_schema_2020_12",
    "remote_habitat_modifications": "none",
    "software_installed": "none",
}

state_path.write_text(
    json.dumps(state, indent=2, ensure_ascii=False) + "\n",
    encoding="utf-8",
)
PYTHON

knowledge_validate
knowledge_generate_views
knowledge_continuity_validate

knowledge_sync \
    "${SANDRA_RUNBOOK_ID}: register Object and Evidence Model"

sandra_assert knowledge_verify_remote
sandra_assert knowledge_validate
sandra_assert knowledge_continuity_validate

{
    printf 'MODEL_VALIDATION=PASS\n'
    printf 'STATE_SHA256=%s\n' \
        "$(sha256sum "${STATE}" | awk '{print $1}')"
    printf 'GIT_HEAD=%s\n' \
        "$(git -C "${ROOT}" rev-parse HEAD)"
    printf 'GIT_ORIGIN_MAIN=%s\n' \
        "$(git -C "${ROOT}" rev-parse origin/main)"
    printf 'REMOTE_HABITAT_MODIFICATIONS=NONE\n'
    printf 'SOFTWARE_INSTALLED=NONE\n'
} > "${SANDRA_EVIDENCE_DIR}/result.env"

sandra_end PASS
