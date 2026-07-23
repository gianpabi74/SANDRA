#!/usr/bin/env bash

source /opt/sandra/core/core.sh
source /opt/sandra/knowledge/knowledge.sh

set -Eeuo pipefail
umask 077

export SANDRA_RUNBOOK_SOURCE="/root/R3-000009D-constitutional-contracts-foundation.sh"

sandra_begin \
    "R3-000009D" \
    "Register SANDRA constitutional operational contracts"

for command_name in \
    python3 git install cp sha256sum grep
do
    sandra_require_command "${command_name}"
done

ROOT="${SANDRA_KNOWLEDGE_ROOT}"
STATE="${ROOT}/STATE.json"

CONSTITUTION_CONTRACT="${ROOT}/docs/architecture/ARCHITECTURE-CONSTITUTION-V1.json"
CONSTITUTION_VALIDATOR="${ROOT}/src/knowledge/validate_architecture_constitution.py"

CONTRACT_ROOT="${ROOT}/docs/contracts/constitutional"
VALIDATOR="${ROOT}/src/knowledge/validate_constitutional_contracts.py"

LIFECYCLE="${CONTRACT_ROOT}/RESOURCE-LIFECYCLE-CONTRACT-V1.json"
EVIDENCE="${CONTRACT_ROOT}/EVIDENCE-AUTHORITY-CONTRACT-V1.json"
CONCURRENCY="${CONTRACT_ROOT}/RECONCILIATION-CONCURRENCY-CONTRACT-V1.json"
EXECUTION="${CONTRACT_ROOT}/EXECUTION-SAFETY-CONTRACT-V1.json"
INDEX="${CONTRACT_ROOT}/CONSTITUTIONAL-CONTRACTS-V1.json"
DOCUMENT="${CONTRACT_ROOT}/README.md"
ADR="${ROOT}/docs/adr/ADR-0008-CONSTITUTIONAL-OPERATIONAL-CONTRACTS.md"

BACKUP_ROOT="${SANDRA_RUN_DIR}/backups"
JOURNAL="$(knowledge_journal_path)"
RUNBOOK_DEST="${ROOT}/src/runbooks/${SANDRA_RUNBOOK_ID}.sh"

sandra_require_file "${STATE}"
sandra_require_file "${CONSTITUTION_CONTRACT}"
sandra_require_file "${CONSTITUTION_VALIDATOR}"

git -C "${ROOT}" diff --quiet
git -C "${ROOT}" diff --cached --quiet

for target in \
    "${LIFECYCLE}" \
    "${EVIDENCE}" \
    "${CONCURRENCY}" \
    "${EXECUTION}" \
    "${INDEX}" \
    "${DOCUMENT}" \
    "${ADR}" \
    "${VALIDATOR}"
do
    if [[ -e "${target}" || -L "${target}" ]]; then
        sandra_fail "Constitutional contract target already exists: ${target}"
    fi
done

install -d -m 0700 "${BACKUP_ROOT}"
cp -a -- "${STATE}" "${BACKUP_ROOT}/STATE.json.before"

install -d -m 0755 \
    "${CONTRACT_ROOT}" \
    "$(dirname "${ADR}")" \
    "$(dirname "${VALIDATOR}")" \
    "$(dirname "${JOURNAL}")" \
    "$(dirname "${RUNBOOK_DEST}")"

cat > "${LIFECYCLE}" <<'EOF'
{
  "apiVersion": "constitution.sandra.io/v1",
  "kind": "ResourceLifecycleContract",
  "metadata": {
    "id": "resource-lifecycle-v1",
    "name": "Resource Lifecycle Contract V1",
    "status": "immutable"
  },
  "spec": {
    "purpose": "govern the birth, evolution, disappearance and retirement of managed resources",
    "states": [
      "discovered",
      "observed",
      "qualified",
      "managed",
      "reconciling",
      "healthy",
      "degraded",
      "unavailable",
      "retiring",
      "retired"
    ],
    "initialState": "discovered",
    "terminalStates": [
      "retired"
    ],
    "rules": [
      "every transition is explicit",
      "every transition identifies the previous and next state",
      "every transition records its cause and evidence references",
      "discovery never implies management authority",
      "temporary unreachability never implies retirement",
      "retirement requires policy authority and verification",
      "retired resources cannot return to managed without a new lifecycle identity"
    ],
    "requiredFields": [
      "lifecycleState",
      "generation",
      "resourceVersion",
      "createdAt",
      "updatedAt",
      "lastTransitionAt",
      "transitionReason",
      "evidenceRefs"
    ],
    "forbiddenBehaviors": [
      "implicit state transition",
      "state transition without evidence",
      "automatic promotion from discovered to managed",
      "automatic retirement from a single failed observation",
      "reuse of a retired resource identity"
    ]
  }
}
EOF

cat > "${EVIDENCE}" <<'EOF'
{
  "apiVersion": "constitution.sandra.io/v1",
  "kind": "EvidenceAuthorityContract",
  "metadata": {
    "id": "evidence-authority-v1",
    "name": "Evidence Authority Contract V1",
    "status": "immutable"
  },
  "spec": {
    "purpose": "qualify observations before they influence authoritative state or execution",
    "requiredFields": [
      "source",
      "sourceType",
      "subjectRef",
      "observedAt",
      "capturedAt",
      "authority",
      "confidence",
      "validUntil",
      "integrity",
      "provenance",
      "rawArtifactRef"
    ],
    "authorityLevels": [
      "unknown",
      "observational",
      "corroborated",
      "authoritative"
    ],
    "confidenceRange": {
      "minimum": 0.0,
      "maximum": 1.0
    },
    "rules": [
      "an observation never modifies authoritative state directly",
      "evidence retains its original provenance",
      "expired evidence cannot authorize execution",
      "conflicting evidence is preserved and explicitly reconciled",
      "authority and confidence are separate properties",
      "confidence alone cannot create authority",
      "promotion to authoritative state requires an explicit qualification decision",
      "raw evidence is immutable after capture"
    ],
    "qualificationOutcomes": [
      "accept",
      "reject",
      "corroborate",
      "conflict",
      "expire",
      "request_more_evidence"
    ],
    "forbiddenBehaviors": [
      "silent evidence overwrite",
      "promotion without qualification",
      "execution based only on expired evidence",
      "discarding conflicting evidence",
      "changing provenance after capture"
    ]
  }
}
EOF

cat > "${CONCURRENCY}" <<'EOF'
{
  "apiVersion": "constitution.sandra.io/v1",
  "kind": "ReconciliationConcurrencyContract",
  "metadata": {
    "id": "reconciliation-concurrency-v1",
    "name": "Reconciliation Concurrency Contract V1",
    "status": "immutable"
  },
  "spec": {
    "purpose": "prevent stale, duplicate or conflicting reconciliation of the same governed resource",
    "requiredFields": [
      "subjectRef",
      "controllerId",
      "reconciliationId",
      "generation",
      "observedGeneration",
      "resourceVersion",
      "startedAt",
      "deadlineAt",
      "idempotencyKey"
    ],
    "rules": [
      "a controller acts only on the generation it evaluated",
      "resourceVersion is checked before committing an authoritative change",
      "observedGeneration is updated only after successful verification",
      "one active mutating reconciliation is allowed per subject and capability",
      "retries reuse the same idempotency key when the intended operation is unchanged",
      "a stale reconciliation must terminate without execution",
      "controller ownership is explicit",
      "lost ownership prevents further mutation"
    ],
    "requiredPreExecutionChecks": [
      "generation_matches",
      "resource_version_matches",
      "controller_owns_reconciliation",
      "no_conflicting_mutation",
      "evidence_is_current",
      "policy_decision_is_current"
    ],
    "outcomes": [
      "converged",
      "requeue",
      "blocked",
      "stale",
      "conflict",
      "failed",
      "cancelled"
    ],
    "forbiddenBehaviors": [
      "blind last-write-wins mutation",
      "parallel mutation of the same subject and capability",
      "execution after ownership loss",
      "verification against a newer unassessed generation",
      "new idempotency key for an unchanged retry"
    ]
  }
}
EOF

cat > "${EXECUTION}" <<'EOF'
{
  "apiVersion": "constitution.sandra.io/v1",
  "kind": "ExecutionSafetyContract",
  "metadata": {
    "id": "execution-safety-v1",
    "name": "Execution Safety Contract V1",
    "status": "immutable"
  },
  "spec": {
    "purpose": "permit autonomous action only when authority, risk boundaries and verification are explicit",
    "requiredFields": [
      "planId",
      "subjectRef",
      "capabilityRef",
      "decisionRef",
      "idempotencyKey",
      "riskClass",
      "authorityMode",
      "preconditions",
      "actions",
      "postconditions",
      "verification",
      "recovery",
      "timeout",
      "retryPolicy",
      "createdAt",
      "expiresAt"
    ],
    "authorityModes": [
      "automatic",
      "conditional",
      "human_approval_required",
      "prohibited"
    ],
    "riskClasses": [
      "low",
      "medium",
      "high",
      "critical",
      "protected"
    ],
    "rules": [
      "execution requires a current policy decision",
      "execution requires current qualified evidence",
      "all preconditions pass before the first mutation",
      "every mutation has a verification method",
      "recovery is defined before execution when reversal is technically possible",
      "irreversible actions are explicitly classified",
      "expired plans cannot execute",
      "retry behavior is bounded",
      "successful command completion is not successful execution until postconditions pass",
      "partial execution is recorded explicitly",
      "automatic execution is allowed only inside policy-delegated limits",
      "habitat survival constraints override service optimization"
    ],
    "requiredResults": [
      "not_started",
      "precondition_failed",
      "executing",
      "verified",
      "verification_failed",
      "partially_applied",
      "recovered",
      "recovery_failed",
      "expired",
      "prohibited"
    ],
    "forbiddenBehaviors": [
      "execution without policy decision",
      "execution without preconditions",
      "execution without verification",
      "unbounded retry",
      "silent partial success",
      "automatic execution outside delegated authority",
      "treating transport success as verified outcome"
    ]
  }
}
EOF

cat > "${INDEX}" <<'EOF'
{
  "apiVersion": "constitution.sandra.io/v1",
  "kind": "ConstitutionalContracts",
  "metadata": {
    "id": "constitutional-operational-contracts-v1",
    "name": "SANDRA Constitutional Operational Contracts V1",
    "status": "immutable"
  },
  "spec": {
    "architectureConstitution": "architecture-constitution-v1",
    "contracts": [
      {
        "id": "resource-lifecycle-v1",
        "path": "docs/contracts/constitutional/RESOURCE-LIFECYCLE-CONTRACT-V1.json"
      },
      {
        "id": "evidence-authority-v1",
        "path": "docs/contracts/constitutional/EVIDENCE-AUTHORITY-CONTRACT-V1.json"
      },
      {
        "id": "reconciliation-concurrency-v1",
        "path": "docs/contracts/constitutional/RECONCILIATION-CONCURRENCY-CONTRACT-V1.json"
      },
      {
        "id": "execution-safety-v1",
        "path": "docs/contracts/constitutional/EXECUTION-SAFETY-CONTRACT-V1.json"
      }
    ],
    "changePolicy": {
      "ordinaryChangeAllowed": false,
      "intuitionChangeAllowed": false,
      "productSpecificChangeAllowed": false,
      "requiresSupersedingADR": true,
      "requiresExplicitUserApproval": true,
      "requiresMigrationAndRollbackPlan": true
    }
  }
}
EOF

cat > "${DOCUMENT}" <<'EOF'
# SANDRA Constitutional Operational Contracts V1

Questi contratti definiscono le invarianti operative sulle quali verranno
costruiti Application Layer, controller e adapter.

## Contratti

1. Resource Lifecycle Contract
2. Evidence Authority Contract
3. Reconciliation Concurrency Contract
4. Execution Safety Contract

## Principio

I contratti sono indipendenti da prodotti e tecnologie.

Proxmox, VMware, Linux, Windows, PBS, OpenVAS, OPA, SSH e qualsiasi futura
tecnologia devono rispettare questi contratti tramite porte e adapter.

## Effetto

Nessun controller o adapter può:

- promuovere automaticamente una scoperta a verità autorevole;
- agire su una generazione obsoleta;
- eseguire due mutazioni concorrenti incompatibili;
- eseguire senza decisione, precondizioni e verifica;
- considerare il successo del comando come prova del risultato;
- superare i limiti di autonomia delegati dalle policy;
- compromettere la sopravvivenza dell'Habitat per ottimizzare un servizio.
EOF

cat > "${ADR}" <<'EOF'
# ADR-0008 — Constitutional Operational Contracts V1

## Stato

Accepted and immutable.

## Decisione

SANDRA adotta quattro contratti costituzionali:

- Resource Lifecycle Contract V1;
- Evidence Authority Contract V1;
- Reconciliation Concurrency Contract V1;
- Execution Safety Contract V1.

## Motivazione

Questi contratti prevengono:

- promozione non governata dello stato scoperto;
- decisioni basate su evidenze obsolete;
- riconciliazioni concorrenti o stale;
- azioni duplicate;
- retry illimitati;
- esecuzioni senza verifica;
- falsi successi basati sul solo exit code;
- autonomia fuori dai limiti di policy.

## Conseguenze

Application Layer, controller e adapter dovranno implementare questi
contratti senza introdurre eccezioni legate a prodotti specifici.
EOF

cat > "${VALIDATOR}" <<'PYTHON'
#!/usr/bin/env python3

from __future__ import annotations

import json
from pathlib import Path
import sys
from typing import Any, NoReturn


EXPECTED = {
    "resource-lifecycle-v1": {
        "kind": "ResourceLifecycleContract",
        "file": "RESOURCE-LIFECYCLE-CONTRACT-V1.json",
    },
    "evidence-authority-v1": {
        "kind": "EvidenceAuthorityContract",
        "file": "EVIDENCE-AUTHORITY-CONTRACT-V1.json",
    },
    "reconciliation-concurrency-v1": {
        "kind": "ReconciliationConcurrencyContract",
        "file": "RECONCILIATION-CONCURRENCY-CONTRACT-V1.json",
    },
    "execution-safety-v1": {
        "kind": "ExecutionSafetyContract",
        "file": "EXECUTION-SAFETY-CONTRACT-V1.json",
    },
}


def fail(message: str) -> NoReturn:
    raise SystemExit(
        f"CONSTITUTIONAL_CONTRACTS_INVALID:{message}"
    )


def load(path: Path) -> dict[str, Any]:
    try:
        document = json.loads(
            path.read_text(encoding="utf-8")
        )
    except FileNotFoundError:
        fail(f"MISSING:{path}")
    except json.JSONDecodeError as exc:
        fail(
            f"JSON:{path}:{exc.lineno}:{exc.colno}"
        )

    if not isinstance(document, dict):
        fail(f"ROOT_NOT_OBJECT:{path}")

    return document


def require_unique_strings(
    value: Any,
    field: str,
) -> list[str]:
    if not isinstance(value, list) or not value:
        fail(f"INVALID_LIST:{field}")

    if not all(
        isinstance(item, str) and item
        for item in value
    ):
        fail(f"INVALID_STRING_LIST:{field}")

    if len(value) != len(set(value)):
        fail(f"DUPLICATE_VALUES:{field}")

    return value


def main() -> int:
    if len(sys.argv) != 4:
        fail("USAGE")

    root = Path(sys.argv[1]).resolve()
    index_path = Path(sys.argv[2]).resolve()
    architecture_path = Path(sys.argv[3]).resolve()

    architecture = load(architecture_path)

    if (
        architecture.get("kind")
        != "ArchitectureConstitution"
    ):
        fail("ARCHITECTURE_KIND")

    if (
        architecture.get("metadata", {}).get("id")
        != "architecture-constitution-v1"
    ):
        fail("ARCHITECTURE_ID")

    index = load(index_path)

    if index.get("kind") != "ConstitutionalContracts":
        fail("INDEX_KIND")

    if (
        index.get("metadata", {}).get("id")
        != "constitutional-operational-contracts-v1"
    ):
        fail("INDEX_ID")

    declared = index.get("spec", {}).get("contracts")

    if not isinstance(declared, list):
        fail("INDEX_CONTRACTS")

    declared_by_id = {
        item.get("id"): item
        for item in declared
        if isinstance(item, dict)
    }

    if set(declared_by_id) != set(EXPECTED):
        fail("INDEX_CONTRACT_SET")

    for identifier, expected in EXPECTED.items():
        item = declared_by_id[identifier]
        relative = item.get("path")

        if not isinstance(relative, str) or not relative:
            fail(f"INDEX_PATH:{identifier}")

        path = root / relative

        if path.name != expected["file"]:
            fail(f"INDEX_FILENAME:{identifier}")

        contract = load(path)

        if contract.get("apiVersion") != (
            "constitution.sandra.io/v1"
        ):
            fail(f"API_VERSION:{identifier}")

        if contract.get("kind") != expected["kind"]:
            fail(f"KIND:{identifier}")

        metadata = contract.get("metadata")

        if not isinstance(metadata, dict):
            fail(f"METADATA:{identifier}")

        if metadata.get("id") != identifier:
            fail(f"IDENTIFIER:{identifier}")

        if metadata.get("status") != "immutable":
            fail(f"STATUS:{identifier}")

        spec = contract.get("spec")

        if not isinstance(spec, dict):
            fail(f"SPEC:{identifier}")

        require_unique_strings(
            spec.get("rules"),
            f"{identifier}.rules",
        )

        require_unique_strings(
            spec.get("forbiddenBehaviors"),
            f"{identifier}.forbiddenBehaviors",
        )

    lifecycle = load(
        root
        / "docs/contracts/constitutional/"
        "RESOURCE-LIFECYCLE-CONTRACT-V1.json"
    )

    states = require_unique_strings(
        lifecycle["spec"].get("states"),
        "lifecycle.states",
    )

    if "discovered" not in states:
        fail("LIFECYCLE_DISCOVERED")

    if "retired" not in states:
        fail("LIFECYCLE_RETIRED")

    evidence = load(
        root
        / "docs/contracts/constitutional/"
        "EVIDENCE-AUTHORITY-CONTRACT-V1.json"
    )

    authority = require_unique_strings(
        evidence["spec"].get("authorityLevels"),
        "evidence.authorityLevels",
    )

    if "authoritative" not in authority:
        fail("EVIDENCE_AUTHORITATIVE")

    concurrency = load(
        root
        / "docs/contracts/constitutional/"
        "RECONCILIATION-CONCURRENCY-CONTRACT-V1.json"
    )

    require_unique_strings(
        concurrency["spec"].get(
            "requiredPreExecutionChecks"
        ),
        "concurrency.requiredPreExecutionChecks",
    )

    execution = load(
        root
        / "docs/contracts/constitutional/"
        "EXECUTION-SAFETY-CONTRACT-V1.json"
    )

    authority_modes = require_unique_strings(
        execution["spec"].get("authorityModes"),
        "execution.authorityModes",
    )

    if "automatic" not in authority_modes:
        fail("EXECUTION_AUTOMATIC")

    if "prohibited" not in authority_modes:
        fail("EXECUTION_PROHIBITED")

    print("CONSTITUTIONAL_CONTRACTS=PASS")
    print("CONSTITUTIONAL_CONTRACT_COUNT=4")
    print("CONSTITUTIONAL_CONTRACT_STATUS=IMMUTABLE")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
PYTHON

chmod 0755 "${VALIDATOR}"
python3 -m py_compile "${VALIDATOR}"

python3 \
    "${CONSTITUTION_VALIDATOR}" \
    "${CONSTITUTION_CONTRACT}" \
    "${ROOT}" \
    > "${SANDRA_EVIDENCE_DIR}/architecture-constitution-validation.txt"

grep -q \
    '^ARCHITECTURE_CONSTITUTION=PASS$' \
    "${SANDRA_EVIDENCE_DIR}/architecture-constitution-validation.txt"

python3 \
    "${VALIDATOR}" \
    "${ROOT}" \
    "${INDEX}" \
    "${CONSTITUTION_CONTRACT}" \
    > "${SANDRA_EVIDENCE_DIR}/constitutional-contracts-validation.txt"

grep -q \
    '^CONSTITUTIONAL_CONTRACTS=PASS$' \
    "${SANDRA_EVIDENCE_DIR}/constitutional-contracts-validation.txt"

python3 - \
    "${STATE}" \
    "${SANDRA_RUNBOOK_ID}" \
    "${SANDRA_RUN_ID}" \
    "${JOURNAL#${ROOT}/}" <<'PYTHON'
from __future__ import annotations

import datetime
import json
from pathlib import Path
import sys

state_path = Path(sys.argv[1])
runbook_id = sys.argv[2]
run_id = sys.argv[3]
journal = sys.argv[4]

state = json.loads(
    state_path.read_text(encoding="utf-8")
)

architecture = state["spec"]["architecture"]
constitution = architecture.get("constitution")

if not isinstance(constitution, dict):
    raise SystemExit(
        "ARCHITECTURE_CONSTITUTION_MISSING"
    )

if (
    constitution.get("id")
    != "architecture-constitution-v1"
):
    raise SystemExit(
        "ARCHITECTURE_CONSTITUTION_ID_INVALID"
    )

state["metadata"]["state_version"] = "4.2.0"
state["metadata"]["updated_utc"] = (
    datetime.datetime.now(
        datetime.timezone.utc
    )
    .replace(microsecond=0)
    .isoformat()
    .replace("+00:00", "Z")
)

state["spec"]["constitutional_contracts"] = {
    "version": "1.0.0",
    "status": "immutable",
    "index": (
        "docs/contracts/constitutional/"
        "CONSTITUTIONAL-CONTRACTS-V1.json"
    ),
    "validator": (
        "src/knowledge/"
        "validate_constitutional_contracts.py"
    ),
    "contracts": {
        "resource_lifecycle": (
            "docs/contracts/constitutional/"
            "RESOURCE-LIFECYCLE-CONTRACT-V1.json"
        ),
        "evidence_authority": (
            "docs/contracts/constitutional/"
            "EVIDENCE-AUTHORITY-CONTRACT-V1.json"
        ),
        "reconciliation_concurrency": (
            "docs/contracts/constitutional/"
            "RECONCILIATION-CONCURRENCY-CONTRACT-V1.json"
        ),
        "execution_safety": (
            "docs/contracts/constitutional/"
            "EXECUTION-SAFETY-CONTRACT-V1.json"
        ),
    },
}

roadmap = state["spec"]["roadmap"]

roadmap["current_gate"] = {
    "runbook": "R3-000009D",
    "title": "Constitutional Operational Contracts",
    "type": "constitutional_contract_registration",
    "targets": [
        "Resource Lifecycle Contract V1",
        "Evidence Authority Contract V1",
        "Reconciliation Concurrency Contract V1",
        "Execution Safety Contract V1",
        "STATE.json",
    ],
    "excluded_targets": [
        "domain implementation",
        "application implementation",
        "controller implementation",
        "adapter implementation",
        "remote Habitat",
        "software installation",
    ],
    "objectives": [
        "define immutable operational invariants",
        "prevent stale or concurrent mutation",
        "prevent unqualified evidence promotion",
        "require safe and verifiable execution",
    ],
    "prohibitions": [
        "no architecture changes",
        "no product-specific exceptions",
        "no Habitat modifications",
        "no software installation",
    ],
}

roadmap["next_gate"] = {
    "runbook": "R3-000009E",
    "title": "Canonical Capability Map V1",
    "status": "blocked",
}

state["status"]["current_certification"] = {
    "runbook": runbook_id,
    "run_id": run_id,
    "journal": journal,
}

state["status"]["roadmap"] = {
    "phase": "Constitutional Operational Contracts",
    "current_gate": "R3-000009D",
    "current_gate_status": "complete",
    "next_gate": "R3-000009E",
}

state["status"]["constitutional_contracts_v1"] = {
    "runbook": runbook_id,
    "run_id": run_id,
    "status": "certified_immutable",
    "contract_count": 4,
    "resource_lifecycle": "pass",
    "evidence_authority": "pass",
    "reconciliation_concurrency": "pass",
    "execution_safety": "pass",
    "architecture_constitution_validation": "pass",
    "software_installed": "none",
    "remote_habitat_modifications": "none",
}

state_path.write_text(
    json.dumps(
        state,
        indent=2,
        ensure_ascii=False,
    )
    + "\n",
    encoding="utf-8",
)
PYTHON

install -m 0600 \
    "${SANDRA_RUNBOOK_SOURCE}" \
    "${RUNBOOK_DEST}"

cat > "${JOURNAL}" <<EOF
# ${SANDRA_RUNBOOK_ID} — Constitutional Operational Contracts

- Run ID: \`${SANDRA_RUN_ID}\`
- Contract count: \`4\`
- Status: \`IMMUTABLE\`
- Architecture changes: \`NONE\`
- Remote Habitat modifications: \`NONE\`
- Software installed: \`NONE\`

## Registered contracts

- Resource Lifecycle Contract V1;
- Evidence Authority Contract V1;
- Reconciliation Concurrency Contract V1;
- Execution Safety Contract V1.

## Result

The contracts were validated, registered in STATE and linked to
Architecture Constitution V1.
EOF

knowledge_validate
knowledge_generate_views
knowledge_continuity_validate

knowledge_sync \
    "${SANDRA_RUNBOOK_ID}: register constitutional operational contracts"

sandra_assert knowledge_verify_remote
sandra_assert knowledge_validate
sandra_assert knowledge_continuity_validate

python3 \
    "${VALIDATOR}" \
    "${ROOT}" \
    "${INDEX}" \
    "${CONSTITUTION_CONTRACT}" \
    > "${SANDRA_EVIDENCE_DIR}/constitutional-contracts-post-sync.txt"

grep -q \
    '^CONSTITUTIONAL_CONTRACTS=PASS$' \
    "${SANDRA_EVIDENCE_DIR}/constitutional-contracts-post-sync.txt"

{
    printf 'CONSTITUTIONAL_CONTRACTS=PASS\n'
    printf 'CONTRACT_COUNT=4\n'
    printf 'RESOURCE_LIFECYCLE=PASS\n'
    printf 'EVIDENCE_AUTHORITY=PASS\n'
    printf 'RECONCILIATION_CONCURRENCY=PASS\n'
    printf 'EXECUTION_SAFETY=PASS\n'
    printf 'CONTRACT_STATUS=IMMUTABLE\n'
    printf 'ARCHITECTURE_CHANGE=NONE\n'
    printf 'STATE_SHA256=%s\n' \
        "$(sha256sum "${STATE}" | awk '{print $1}')"
    printf 'INDEX_SHA256=%s\n' \
        "$(sha256sum "${INDEX}" | awk '{print $1}')"
    printf 'GIT_HEAD=%s\n' \
        "$(git -C "${ROOT}" rev-parse HEAD)"
    printf 'GIT_ORIGIN_MAIN=%s\n' \
        "$(git -C "${ROOT}" rev-parse origin/main)"
    printf 'REMOTE_HABITAT_MODIFICATIONS=NONE\n'
    printf 'SOFTWARE_INSTALLED=NONE\n'
} > "${SANDRA_EVIDENCE_DIR}/result.env"

sandra_end PASS
