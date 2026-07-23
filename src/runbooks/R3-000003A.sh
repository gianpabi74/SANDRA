#!/usr/bin/env bash

source /opt/sandra/core/core.sh
source /opt/sandra/knowledge/knowledge.sh

set -Eeuo pipefail
umask 077

export SANDRA_RUNBOOK_SOURCE="/root/R3-000003A-capability-policy-contract.sh"

sandra_begin \
    "R3-000003A" \
    "Register Capability and Policy Contract"

for command_name in python3 git install cp sha256sum; do
    sandra_require_command "${command_name}"
done

ROOT="${SANDRA_KNOWLEDGE_ROOT}"
STATE="${ROOT}/STATE.json"
SPEC_ROOT="${ROOT}/docs/specs/governance-model"
SCHEMA_ROOT="${SPEC_ROOT}/schemas"
EXAMPLE_ROOT="${SPEC_ROOT}/examples"
CATALOG_ROOT="${ROOT}/catalog"
CAPABILITY_ROOT="${CATALOG_ROOT}/capabilities"
POLICY_ROOT="${CATALOG_ROOT}/policies"
BACKUP_ROOT="${SANDRA_RUN_DIR}/backups"
JOURNAL="$(knowledge_journal_path)"
RUNBOOK_DEST="${ROOT}/src/runbooks/${SANDRA_RUNBOOK_ID}.sh"

TARGET_FILES=(
    "${STATE}"
    "${SPEC_ROOT}/CAPABILITY-AND-POLICY-CONTRACT.md"
    "${SCHEMA_ROOT}/capability.schema.json"
    "${SCHEMA_ROOT}/policy.schema.json"
    "${SCHEMA_ROOT}/policy-decision.schema.json"
    "${SCHEMA_ROOT}/execution-plan.schema.json"
    "${EXAMPLE_ROOT}/capability.example.json"
    "${EXAMPLE_ROOT}/policy.example.json"
    "${EXAMPLE_ROOT}/policy-decision.example.json"
    "${EXAMPLE_ROOT}/execution-plan.example.json"
    "${CAPABILITY_ROOT}/compute.memory.resize.json"
    "${POLICY_ROOT}/resource-elasticity.json"
)

sandra_require_file "${STATE}"
sandra_require_file \
    "${SCHEMA_ROOT}/managed-object.schema.json"
sandra_require_file \
    "${SCHEMA_ROOT}/evidence.schema.json"

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
    "${CAPABILITY_ROOT}" \
    "${POLICY_ROOT}" \
    "$(dirname "${JOURNAL}")"

install -m 0600 \
    "${SANDRA_RUNBOOK_SOURCE}" \
    "${RUNBOOK_DEST}"

cat > "${SPEC_ROOT}/CAPABILITY-AND-POLICY-CONTRACT.md" <<'EOF'
# Capability and Policy Contract

## Stato

Canonical V1.

## Capability

Una Capability è un contratto astratto, versionato e indipendente dalla
tecnologia che lo implementa.

Una Capability definisce:

- identificatore;
- versione;
- scopo;
- input;
- output;
- precondizioni;
- postcondizioni;
- livello di rischio;
- reversibilità;
- strategia di verifica;
- strategia di recovery;
- compatibilità con gli adapter.

Una Capability non contiene:

- hostname;
- indirizzi IP;
- VMID;
- nomi di prodotti;
- policy specifiche di un singolo oggetto;
- credenziali;
- comandi concreti dell'implementazione.

## Policy

Una Policy assegna authority a una Capability per oggetti selezionati mediante
classificazioni, ruoli, protection profile e condizioni osservate.

La Policy produce esclusivamente uno dei seguenti risultati:

- `autonomous`
- `conditional_autonomous`
- `escalate`
- `denied`

`escalate` non è un consenso preventivo ordinario. Indica che le regole
disponibili non consentono una decisione univoca.

`denied` non può essere trasformato in `autonomous` mediante un'approvazione
occasionale. Richiede una modifica esplicita e versionata della Policy.

## Policy Decision

Una Policy Decision deve registrare:

- policy valutate;
- revisione delle policy;
- Capability richiesta;
- oggetto interessato;
- evidenze considerate;
- risultato;
- condizioni obbligatorie;
- limiti;
- motivazioni;
- timestamp;
- decision identifier.

## Execution Plan

Un Execution Plan è immutabile dopo la creazione.

Contiene:

- riferimenti alla decisione;
- target;
- Capability;
- adapter selezionato;
- precheck;
- azioni;
- postcheck;
- recovery;
- limiti;
- scadenza;
- hash del piano.

Il piano non può essere eseguito se:

- la decisione è scaduta;
- lo stato osservato è cambiato oltre i limiti dichiarati;
- l'adapter non implementa la Capability nella versione richiesta;
- una precondizione è falsa;
- le evidenze sono conflittuali;
- il piano non è verificabile.

## Autonomia

L'autonomia viene concessa alla combinazione:

- Capability;
- versione Capability;
- adapter;
- versione adapter;
- selettore degli oggetti;
- limiti;
- condizioni;
- metodo di verifica.

Non viene concessa genericamente all'intero runtime.

## Progressive Trust

Stati ammessi:

- `disabled`
- `observe_only`
- `recommend`
- `approval_required`
- `autonomous_canary`
- `autonomous`
- `suspended`

Il passaggio a un livello superiore richiede evidenze registrate.

Errori ripetuti, rollback o mismatch di verifica possono sospendere
automaticamente la Capability.

## Principi

- la Policy decide;
- l'enforcement applica;
- l'adapter traduce;
- lo strumento opera;
- il verifier dimostra il risultato;
- ogni azione autonoma resta entro budget espliciti;
- nessun oggetto concreto viene codificato nella Capability;
- nessuna decisione viene incorporata nell'adapter.
EOF

cat > "${SCHEMA_ROOT}/capability.schema.json" <<'EOF'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://sandra.local/schemas/capability.schema.json",
  "title": "Capability",
  "type": "object",
  "additionalProperties": false,
  "required": [
    "apiVersion",
    "kind",
    "metadata",
    "spec"
  ],
  "properties": {
    "apiVersion": {
      "const": "governance.sandra.io/v1"
    },
    "kind": {
      "const": "Capability"
    },
    "metadata": {
      "type": "object",
      "additionalProperties": false,
      "required": [
        "id",
        "version",
        "title"
      ],
      "properties": {
        "id": {
          "type": "string",
          "pattern": "^[a-z][a-z0-9]*(\\.[a-z][a-z0-9_]*)+$"
        },
        "version": {
          "type": "integer",
          "minimum": 1
        },
        "title": {
          "type": "string",
          "minLength": 1
        }
      }
    },
    "spec": {
      "type": "object",
      "additionalProperties": false,
      "required": [
        "description",
        "inputSchema",
        "outputSchema",
        "riskClass",
        "reversibility",
        "preconditions",
        "postconditions",
        "verification",
        "recovery",
        "trustState"
      ],
      "properties": {
        "description": {
          "type": "string",
          "minLength": 1
        },
        "inputSchema": {
          "type": "object"
        },
        "outputSchema": {
          "type": "object"
        },
        "riskClass": {
          "enum": [
            "low",
            "medium",
            "high",
            "critical"
          ]
        },
        "reversibility": {
          "enum": [
            "automatic",
            "conditional",
            "recovery_only",
            "irreversible"
          ]
        },
        "preconditions": {
          "type": "array",
          "items": {
            "type": "string",
            "minLength": 1
          },
          "uniqueItems": true
        },
        "postconditions": {
          "type": "array",
          "items": {
            "type": "string",
            "minLength": 1
          },
          "uniqueItems": true
        },
        "verification": {
          "type": "object",
          "additionalProperties": false,
          "required": [
            "required",
            "independent",
            "contract"
          ],
          "properties": {
            "required": {
              "const": true
            },
            "independent": {
              "type": "boolean"
            },
            "contract": {
              "type": "string",
              "minLength": 1
            }
          }
        },
        "recovery": {
          "type": "object",
          "additionalProperties": false,
          "required": [
            "required",
            "strategy"
          ],
          "properties": {
            "required": {
              "type": "boolean"
            },
            "strategy": {
              "type": "string",
              "minLength": 1
            }
          }
        },
        "trustState": {
          "enum": [
            "disabled",
            "observe_only",
            "recommend",
            "approval_required",
            "autonomous_canary",
            "autonomous",
            "suspended"
          ]
        }
      }
    }
  }
}
EOF

cat > "${SCHEMA_ROOT}/policy.schema.json" <<'EOF'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://sandra.local/schemas/policy.schema.json",
  "title": "GovernancePolicy",
  "type": "object",
  "additionalProperties": false,
  "required": [
    "apiVersion",
    "kind",
    "metadata",
    "spec"
  ],
  "properties": {
    "apiVersion": {
      "const": "governance.sandra.io/v1"
    },
    "kind": {
      "const": "GovernancePolicy"
    },
    "metadata": {
      "type": "object",
      "additionalProperties": false,
      "required": [
        "id",
        "version",
        "title"
      ],
      "properties": {
        "id": {
          "type": "string",
          "pattern": "^policy\\.[a-z][a-z0-9_.]*$"
        },
        "version": {
          "type": "integer",
          "minimum": 1
        },
        "title": {
          "type": "string",
          "minLength": 1
        }
      }
    },
    "spec": {
      "type": "object",
      "additionalProperties": false,
      "required": [
        "capability",
        "selector",
        "outcomes",
        "conditions",
        "limits",
        "evidenceRequirements",
        "verificationRequirements"
      ],
      "properties": {
        "capability": {
          "type": "object",
          "additionalProperties": false,
          "required": [
            "id",
            "minimumVersion"
          ],
          "properties": {
            "id": {
              "type": "string"
            },
            "minimumVersion": {
              "type": "integer",
              "minimum": 1
            }
          }
        },
        "selector": {
          "type": "object",
          "additionalProperties": false,
          "required": [
            "matchLabels",
            "roles",
            "protectionProfiles"
          ],
          "properties": {
            "matchLabels": {
              "type": "object",
              "additionalProperties": {
                "type": "string"
              }
            },
            "roles": {
              "type": "array",
              "items": {
                "type": "string"
              },
              "uniqueItems": true
            },
            "protectionProfiles": {
              "type": "array",
              "items": {
                "enum": [
                  "protected",
                  "critical",
                  "standard",
                  "disposable"
                ]
              },
              "uniqueItems": true
            }
          }
        },
        "outcomes": {
          "type": "array",
          "items": {
            "enum": [
              "autonomous",
              "conditional_autonomous",
              "escalate",
              "denied"
            ]
          },
          "minItems": 1,
          "uniqueItems": true
        },
        "conditions": {
          "type": "array",
          "items": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "id",
              "expression",
              "onFalse"
            ],
            "properties": {
              "id": {
                "type": "string"
              },
              "expression": {
                "type": "string",
                "minLength": 1
              },
              "onFalse": {
                "enum": [
                  "escalate",
                  "denied"
                ]
              }
            }
          }
        },
        "limits": {
          "type": "object"
        },
        "evidenceRequirements": {
          "type": "object",
          "additionalProperties": false,
          "required": [
            "minimumAuthority",
            "maximumAgeSeconds",
            "conflictsAllowed"
          ],
          "properties": {
            "minimumAuthority": {
              "enum": [
                "authoritative",
                "corroborated",
                "candidate"
              ]
            },
            "maximumAgeSeconds": {
              "type": "integer",
              "minimum": 1
            },
            "conflictsAllowed": {
              "const": false
            }
          }
        },
        "verificationRequirements": {
          "type": "object",
          "additionalProperties": false,
          "required": [
            "mandatory",
            "independent"
          ],
          "properties": {
            "mandatory": {
              "const": true
            },
            "independent": {
              "type": "boolean"
            }
          }
        }
      }
    }
  }
}
EOF

cat > "${SCHEMA_ROOT}/policy-decision.schema.json" <<'EOF'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://sandra.local/schemas/policy-decision.schema.json",
  "title": "PolicyDecision",
  "type": "object",
  "additionalProperties": false,
  "required": [
    "apiVersion",
    "kind",
    "metadata",
    "subjectRef",
    "capabilityRef",
    "policyRefs",
    "evidenceRefs",
    "outcome",
    "conditions",
    "limits",
    "reasons",
    "decidedAt",
    "expiresAt"
  ],
  "properties": {
    "apiVersion": {
      "const": "governance.sandra.io/v1"
    },
    "kind": {
      "const": "PolicyDecision"
    },
    "metadata": {
      "type": "object",
      "additionalProperties": false,
      "required": [
        "id",
        "revision"
      ],
      "properties": {
        "id": {
          "type": "string",
          "pattern": "^dec_[a-z0-9]{16,64}$"
        },
        "revision": {
          "type": "integer",
          "minimum": 1
        }
      }
    },
    "subjectRef": {
      "type": "string"
    },
    "capabilityRef": {
      "type": "string"
    },
    "policyRefs": {
      "type": "array",
      "items": {
        "type": "string"
      },
      "minItems": 1,
      "uniqueItems": true
    },
    "evidenceRefs": {
      "type": "array",
      "items": {
        "type": "string"
      },
      "minItems": 1,
      "uniqueItems": true
    },
    "outcome": {
      "enum": [
        "autonomous",
        "conditional_autonomous",
        "escalate",
        "denied"
      ]
    },
    "conditions": {
      "type": "array",
      "items": {
        "type": "string"
      },
      "uniqueItems": true
    },
    "limits": {
      "type": "object"
    },
    "reasons": {
      "type": "array",
      "items": {
        "type": "string"
      },
      "minItems": 1
    },
    "decidedAt": {
      "type": "string",
      "format": "date-time"
    },
    "expiresAt": {
      "type": "string",
      "format": "date-time"
    }
  }
}
EOF

cat > "${SCHEMA_ROOT}/execution-plan.schema.json" <<'EOF'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://sandra.local/schemas/execution-plan.schema.json",
  "title": "ExecutionPlan",
  "type": "object",
  "additionalProperties": false,
  "required": [
    "apiVersion",
    "kind",
    "metadata",
    "decisionRef",
    "subjectRef",
    "capabilityRef",
    "adapter",
    "prechecks",
    "actions",
    "postchecks",
    "recovery",
    "limits",
    "createdAt",
    "expiresAt",
    "digest"
  ],
  "properties": {
    "apiVersion": {
      "const": "governance.sandra.io/v1"
    },
    "kind": {
      "const": "ExecutionPlan"
    },
    "metadata": {
      "type": "object",
      "additionalProperties": false,
      "required": [
        "id",
        "revision"
      ],
      "properties": {
        "id": {
          "type": "string",
          "pattern": "^plan_[a-z0-9]{16,64}$"
        },
        "revision": {
          "type": "integer",
          "minimum": 1
        }
      }
    },
    "decisionRef": {
      "type": "string"
    },
    "subjectRef": {
      "type": "string"
    },
    "capabilityRef": {
      "type": "string"
    },
    "adapter": {
      "type": "object",
      "additionalProperties": false,
      "required": [
        "id",
        "version"
      ],
      "properties": {
        "id": {
          "type": "string"
        },
        "version": {
          "type": "string"
        }
      }
    },
    "prechecks": {
      "type": "array",
      "items": {
        "type": "string"
      },
      "minItems": 1
    },
    "actions": {
      "type": "array",
      "items": {
        "type": "string"
      },
      "minItems": 1
    },
    "postchecks": {
      "type": "array",
      "items": {
        "type": "string"
      },
      "minItems": 1
    },
    "recovery": {
      "type": "array",
      "items": {
        "type": "string"
      }
    },
    "limits": {
      "type": "object"
    },
    "createdAt": {
      "type": "string",
      "format": "date-time"
    },
    "expiresAt": {
      "type": "string",
      "format": "date-time"
    },
    "digest": {
      "type": "object",
      "additionalProperties": false,
      "required": [
        "algorithm",
        "value"
      ],
      "properties": {
        "algorithm": {
          "const": "sha256"
        },
        "value": {
          "type": "string",
          "pattern": "^[a-f0-9]{64}$"
        }
      }
    }
  }
}
EOF

cat > "${CAPABILITY_ROOT}/compute.memory.resize.json" <<'EOF'
{
  "apiVersion": "governance.sandra.io/v1",
  "kind": "Capability",
  "metadata": {
    "id": "compute.memory.resize",
    "version": 1,
    "title": "Resize compute workload memory"
  },
  "spec": {
    "description": "Change the assigned memory of a managed compute workload.",
    "inputSchema": {
      "type": "object",
      "required": [
        "currentMiB",
        "requestedMiB"
      ],
      "properties": {
        "currentMiB": {
          "type": "integer",
          "minimum": 1
        },
        "requestedMiB": {
          "type": "integer",
          "minimum": 1
        }
      }
    },
    "outputSchema": {
      "type": "object",
      "required": [
        "assignedMiB"
      ],
      "properties": {
        "assignedMiB": {
          "type": "integer",
          "minimum": 1
        }
      }
    },
    "riskClass": "high",
    "reversibility": "conditional",
    "preconditions": [
      "subject identity confirmed",
      "adapter supports requested operation",
      "habitat reserve remains satisfied",
      "no conflicting execution exists"
    ],
    "postconditions": [
      "platform reports requested allocation",
      "guest reports expected allocation when applicable",
      "subject remains available",
      "habitat reserve remains satisfied"
    ],
    "verification": {
      "required": true,
      "independent": true,
      "contract": "compute.memory.assignment.verify"
    },
    "recovery": {
      "required": true,
      "strategy": "restore previous allocation when supported and safe"
    },
    "trustState": "observe_only"
  }
}
EOF

cat > "${POLICY_ROOT}/resource-elasticity.json" <<'EOF'
{
  "apiVersion": "governance.sandra.io/v1",
  "kind": "GovernancePolicy",
  "metadata": {
    "id": "policy.resource_elasticity",
    "version": 1,
    "title": "Temporary resource elasticity"
  },
  "spec": {
    "capability": {
      "id": "compute.memory.resize",
      "minimumVersion": 1
    },
    "selector": {
      "matchLabels": {
        "resource-elasticity": "enabled"
      },
      "roles": [
        "application-workload"
      ],
      "protectionProfiles": [
        "standard"
      ]
    },
    "outcomes": [
      "conditional_autonomous",
      "escalate",
      "denied"
    ],
    "conditions": [
      {
        "id": "pressure_confirmed",
        "expression": "memory pressure is persistent and corroborated",
        "onFalse": "denied"
      },
      {
        "id": "habitat_reserve",
        "expression": "post-allocation habitat reserve remains satisfied",
        "onFalse": "denied"
      },
      {
        "id": "operation_supported",
        "expression": "adapter supports online resize and verification",
        "onFalse": "escalate"
      }
    ],
    "limits": {
      "maximumFractionOfCurrentlyAvailable": 0.30,
      "temporaryLeaseRequired": true,
      "rollbackOnNoImprovement": true
    },
    "evidenceRequirements": {
      "minimumAuthority": "corroborated",
      "maximumAgeSeconds": 300,
      "conflictsAllowed": false
    },
    "verificationRequirements": {
      "mandatory": true,
      "independent": true
    }
  }
}
EOF

cp -a \
    "${CAPABILITY_ROOT}/compute.memory.resize.json" \
    "${EXAMPLE_ROOT}/capability.example.json"

cp -a \
    "${POLICY_ROOT}/resource-elasticity.json" \
    "${EXAMPLE_ROOT}/policy.example.json"

cat > "${EXAMPLE_ROOT}/policy-decision.example.json" <<'EOF'
{
  "apiVersion": "governance.sandra.io/v1",
  "kind": "PolicyDecision",
  "metadata": {
    "id": "dec_01k0example000001",
    "revision": 1
  },
  "subjectRef": "obj_01k0example000001",
  "capabilityRef": "compute.memory.resize@1",
  "policyRefs": [
    "policy.resource_elasticity@1"
  ],
  "evidenceRefs": [
    "evd_01k0example000001"
  ],
  "outcome": "conditional_autonomous",
  "conditions": [
    "habitat reserve remains satisfied",
    "adapter supports online resize"
  ],
  "limits": {
    "maximumFractionOfCurrentlyAvailable": 0.30
  },
  "reasons": [
    "persistent memory pressure",
    "resource elasticity delegated by policy"
  ],
  "decidedAt": "2026-07-23T12:40:00Z",
  "expiresAt": "2026-07-23T12:45:00Z"
}
EOF

cat > "${EXAMPLE_ROOT}/execution-plan.example.json" <<'EOF'
{
  "apiVersion": "governance.sandra.io/v1",
  "kind": "ExecutionPlan",
  "metadata": {
    "id": "plan_01k0example000001",
    "revision": 1
  },
  "decisionRef": "dec_01k0example000001",
  "subjectRef": "obj_01k0example000001",
  "capabilityRef": "compute.memory.resize@1",
  "adapter": {
    "id": "example-compute-adapter",
    "version": "1.0.0"
  },
  "prechecks": [
    "verify object identity",
    "verify habitat reserve",
    "verify adapter compatibility"
  ],
  "actions": [
    "apply approved memory increment"
  ],
  "postchecks": [
    "verify platform allocation",
    "verify workload availability",
    "verify habitat reserve"
  ],
  "recovery": [
    "restore previous allocation if verification fails and recovery is safe"
  ],
  "limits": {
    "maximumFractionOfCurrentlyAvailable": 0.30
  },
  "createdAt": "2026-07-23T12:40:01Z",
  "expiresAt": "2026-07-23T12:45:00Z",
  "digest": {
    "algorithm": "sha256",
    "value": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  }
}
EOF

python3 - \
    "${SCHEMA_ROOT}" \
    "${EXAMPLE_ROOT}" \
    "${CAPABILITY_ROOT}" \
    "${POLICY_ROOT}" <<'PYTHON'
import json
import pathlib
import re
import sys

schema_root = pathlib.Path(sys.argv[1])
example_root = pathlib.Path(sys.argv[2])
capability_root = pathlib.Path(sys.argv[3])
policy_root = pathlib.Path(sys.argv[4])

required_schemas = {
    "capability.schema.json",
    "policy.schema.json",
    "policy-decision.schema.json",
    "execution-plan.schema.json",
}

actual_schemas = {
    path.name
    for path in schema_root.glob("*.json")
}

if not required_schemas.issubset(actual_schemas):
    raise SystemExit("CAPABILITY_POLICY_SCHEMA_MISSING")

for path in sorted(schema_root.glob("*.json")):
    document = json.loads(path.read_text(encoding="utf-8"))

    if document.get("$schema") != (
        "https://json-schema.org/draft/2020-12/schema"
    ):
        raise SystemExit(f"SCHEMA_DRAFT_INVALID:{path}")

for path in sorted(
    list(example_root.glob("*.json"))
    + list(capability_root.glob("*.json"))
    + list(policy_root.glob("*.json"))
):
    document = json.loads(path.read_text(encoding="utf-8"))

    if document.get("apiVersion") != "governance.sandra.io/v1":
        raise SystemExit(f"API_VERSION_INVALID:{path}")

    if not document.get("kind"):
        raise SystemExit(f"KIND_MISSING:{path}")

capability = json.loads(
    (
        capability_root
        / "compute.memory.resize.json"
    ).read_text(encoding="utf-8")
)

if capability["metadata"]["id"] != "compute.memory.resize":
    raise SystemExit("CAPABILITY_ID_INVALID")

if capability["spec"]["trustState"] != "observe_only":
    raise SystemExit("INITIAL_TRUST_STATE_INVALID")

policy = json.loads(
    (
        policy_root
        / "resource-elasticity.json"
    ).read_text(encoding="utf-8")
)

if policy["spec"]["capability"]["id"] != (
    capability["metadata"]["id"]
):
    raise SystemExit("POLICY_CAPABILITY_MISMATCH")

if (
    policy["spec"]["limits"]
    ["maximumFractionOfCurrentlyAvailable"]
    != 0.30
):
    raise SystemExit("RESOURCE_ELASTICITY_LIMIT_INVALID")

allowed_outcomes = {
    "autonomous",
    "conditional_autonomous",
    "escalate",
    "denied",
}

if not set(policy["spec"]["outcomes"]).issubset(
    allowed_outcomes
):
    raise SystemExit("POLICY_OUTCOME_INVALID")

print("CAPABILITY_POLICY_CONTRACT_VALIDATION=PASS")
PYTHON

cat > "${ROOT}/docs/adr/ADR-0006-CAPABILITY-POLICY-SEPARATION.md" <<'EOF'
# ADR-0006 — Capability, policy and enforcement separation

## Stato

Accepted.

## Decisione

- Capability descrive l'operazione astratta.
- Policy assegna authority, condizioni e limiti.
- Policy Decision registra l'esito.
- Execution Plan traduce la decisione in passi immutabili.
- Adapter ed executor applicano il piano.
- Verifier dimostra il risultato.

Il motore di policy resta separato dall'enforcement.

Open Policy Agent rimane il candidato primario, ma non viene installato
finché input, output e primi test non sono definiti.

## Riferimenti ufficiali

- https://www.openpolicyagent.org/docs
- https://www.openpolicyagent.org/docs/philosophy
- https://www.openpolicyagent.org/docs/management-decision-logs
EOF

install -d -m 0755 "$(dirname "${JOURNAL}")"

cat > "${JOURNAL}" <<EOF
# ${SANDRA_RUNBOOK_ID} — Capability and Policy Contract

- Run ID: \`${SANDRA_RUN_ID}\`
- Modifiche remote all'Habitat: \`NONE\`
- Nuovi software installati: \`NONE\`

## Risultato

- definita Capability;
- definita Governance Policy;
- definiti Policy Decision ed Execution Plan;
- registrati esiti autonomi, escalation e deny;
- definito progressive trust;
- registrata capability iniziale compute.memory.resize;
- registrata policy iniziale resource elasticity;
- registrato ADR-0006.
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
    "R3-000002",
    "R3-000003",
}:
    raise SystemExit(
        f"STATE_UNEXPECTED_CURRENT_GATE:{current_gate}"
    )

state["metadata"]["state_version"] = "3.2.0"
state["metadata"]["updated_utc"] = (
    datetime.datetime.now(datetime.timezone.utc)
    .replace(microsecond=0)
    .isoformat()
    .replace("+00:00", "Z")
)

state["spec"]["roadmap"]["current_gate"] = {
    "runbook": "R3-000003",
    "title": "Capability and Policy Contract",
    "type": "governance_contract",
    "targets": [
        "Knowledge canonica",
        "Capability catalog",
        "Policy catalog",
    ],
    "excluded_targets": [
        "sistemi remoti dell'Habitat",
        "runtime operativa",
    ],
    "objectives": [
        "definire Capability",
        "definire Governance Policy",
        "definire Policy Decision",
        "definire Execution Plan",
        "definire progressive trust",
        "registrare prima capability e prima policy",
    ],
    "prohibitions": [
        "nessuna modifica remota",
        "nessuna installazione software",
        "nessuna policy codificata nell'adapter",
        "nessun oggetto concreto nella Capability",
        "nessuna correzione ad intuito",
    ],
}

state["spec"]["roadmap"]["next_gate"] = {
    "runbook": "R3-000004",
    "title": "Adapter and Execution Contract",
    "status": "blocked",
}

state["status"]["current_certification"] = {
    "runbook": runbook_id,
    "run_id": run_id,
    "journal": journal,
}

state["status"]["roadmap"] = {
    "phase": "Capability and Policy Contract",
    "current_gate": "R3-000003",
    "current_gate_status": "complete",
    "next_gate": "R3-000004",
}

state["status"]["capability_policy_contract_v1"] = {
    "runbook": runbook_id,
    "run_id": run_id,
    "status": "certified",
    "capability_schema": "defined",
    "policy_schema": "defined",
    "policy_decision_schema": "defined",
    "execution_plan_schema": "defined",
    "initial_capability": "compute.memory.resize@1",
    "initial_policy": "policy.resource_elasticity@1",
    "initial_trust_state": "observe_only",
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
    "${SANDRA_RUNBOOK_ID}: register Capability and Policy Contract"

sandra_assert knowledge_verify_remote
sandra_assert knowledge_validate
sandra_assert knowledge_continuity_validate

{
    printf 'CONTRACT_VALIDATION=PASS\n'
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
