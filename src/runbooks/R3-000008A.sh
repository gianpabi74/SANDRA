#!/usr/bin/env bash

source /opt/sandra/core/core.sh
source /opt/sandra/knowledge/knowledge.sh

set -Eeuo pipefail
umask 077

export SANDRA_RUNBOOK_SOURCE="/root/R3-000008A-architecture-granita-freeze.sh"

sandra_begin \
    "R3-000008A" \
    "Register Architecture GRANITA Freeze V1"

for command_name in \
    python3 git install cp sha256sum
do
    sandra_require_command "${command_name}"
done

ROOT="${SANDRA_KNOWLEDGE_ROOT}"
STATE="${ROOT}/STATE.json"
MANIFEST="${ROOT}/manifest/KNOWLEDGE_MANIFEST.json"

FREEZE_DOC="${ROOT}/docs/architecture/ARCHITECTURE-FREEZE-V1.md"
FREEZE_CONTRACT="${ROOT}/docs/architecture/ARCHITECTURE-FREEZE-V1.json"
FREEZE_ADR="${ROOT}/docs/adr/ADR-0007-ARCHITECTURE-GRANITA-FREEZE.md"
FREEZE_VALIDATOR="${ROOT}/src/knowledge/validate_architecture_freeze.py"

SANDRA_ROOT="${ROOT}/src/sandra"
TEST_ROOT="${ROOT}/tests"

BACKUP_ROOT="${SANDRA_RUN_DIR}/backups"
JOURNAL="$(knowledge_journal_path)"
RUNBOOK_DEST="${ROOT}/src/runbooks/${SANDRA_RUNBOOK_ID}.sh"

sandra_require_file "${STATE}"
sandra_require_file "${MANIFEST}"

install -d -m 0700 "${BACKUP_ROOT}"

cp -a -- \
    "${STATE}" \
    "${BACKUP_ROOT}/STATE.json.before"

cp -a -- \
    "${MANIFEST}" \
    "${BACKUP_ROOT}/KNOWLEDGE_MANIFEST.json.before"

for target in \
    "${FREEZE_DOC}" \
    "${FREEZE_CONTRACT}" \
    "${FREEZE_ADR}" \
    "${FREEZE_VALIDATOR}"
do
    if [[ -f "${target}" ]]; then
        relative="${target#${ROOT}/}"
        backup="${BACKUP_ROOT}/${relative}"

        install -d -m 0700 "$(dirname "${backup}")"
        cp -a -- "${target}" "${backup}"
    fi
done

install -d -m 0755 \
    "${ROOT}/docs/architecture" \
    "${ROOT}/docs/adr" \
    "${SANDRA_ROOT}/domain" \
    "${SANDRA_ROOT}/application/ports/inbound" \
    "${SANDRA_ROOT}/application/ports/outbound" \
    "${SANDRA_ROOT}/application/use_cases" \
    "${SANDRA_ROOT}/controllers/security" \
    "${SANDRA_ROOT}/adapters/inbound" \
    "${SANDRA_ROOT}/adapters/outbound/compute" \
    "${SANDRA_ROOT}/adapters/outbound/operating_system" \
    "${SANDRA_ROOT}/adapters/outbound/backup" \
    "${SANDRA_ROOT}/adapters/outbound/network" \
    "${SANDRA_ROOT}/adapters/outbound/observability" \
    "${SANDRA_ROOT}/adapters/outbound/persistence" \
    "${SANDRA_ROOT}/adapters/outbound/policy_engine" \
    "${SANDRA_ROOT}/adapters/outbound/security" \
    "${SANDRA_ROOT}/bootstrap" \
    "${TEST_ROOT}/unit" \
    "${TEST_ROOT}/contract" \
    "${TEST_ROOT}/integration" \
    "$(dirname "${JOURNAL}")" \
    "$(dirname "${RUNBOOK_DEST}")"

cat > "${FREEZE_CONTRACT}" <<'EOF'
{
  "apiVersion": "architecture.sandra.io/v1",
  "kind": "ArchitectureFreeze",
  "metadata": {
    "id": "architecture-granita-v1",
    "name": "SANDRA Architecture GRANITA Freeze V1",
    "status": "immutable",
    "scope": "until-project-completion"
  },
  "spec": {
    "sourceRoot": "src/sandra",
    "testRoot": "tests",
    "immutableLayers": [
      "domain",
      "application",
      "controllers",
      "adapters",
      "bootstrap"
    ],
    "requiredPaths": [
      "src/sandra/domain",
      "src/sandra/application/ports/inbound",
      "src/sandra/application/ports/outbound",
      "src/sandra/application/use_cases",
      "src/sandra/controllers",
      "src/sandra/controllers/security",
      "src/sandra/adapters/inbound",
      "src/sandra/adapters/outbound/compute",
      "src/sandra/adapters/outbound/operating_system",
      "src/sandra/adapters/outbound/backup",
      "src/sandra/adapters/outbound/network",
      "src/sandra/adapters/outbound/observability",
      "src/sandra/adapters/outbound/persistence",
      "src/sandra/adapters/outbound/policy_engine",
      "src/sandra/adapters/outbound/security",
      "src/sandra/bootstrap",
      "tests/unit",
      "tests/contract",
      "tests/integration",
      "src/runbooks"
    ],
    "forbiddenPaths": [
      "src/sandra/interfaces",
      "src/sandra/runtime",
      "src/sandra/provider",
      "src/sandra/providers",
      "src/sandra/policy"
    ],
    "operationalCycle": [
      "observe",
      "reconcile",
      "evaluate_policy",
      "plan",
      "execute",
      "verify",
      "record"
    ],
    "resourceEnvelope": [
      "apiVersion",
      "kind",
      "metadata",
      "spec",
      "status"
    ],
    "security": {
      "permanentFunctionalFamily": true,
      "controllerPath": "src/sandra/controllers/security",
      "adapterPath": "src/sandra/adapters/outbound/security",
      "firstCandidate": "openvas-greenbone"
    },
    "changePolicy": {
      "ordinaryChangeAllowed": false,
      "preferenceChangeAllowed": false,
      "intuitionChangeAllowed": false,
      "renameAllowed": false,
      "layerMovementAllowed": false
    }
  }
}
EOF

cat > "${FREEZE_DOC}" <<'EOF'
# SANDRA Architecture GRANITA Freeze V1

## Stato

**IMMUTABILE FINO ALLA FINE DEL PROGETTO**

La struttura canonica di SANDRA è:

    src/
    ├── core/
    ├── knowledge/
    ├── sandra/
    │   ├── domain/
    │   ├── application/
    │   │   ├── ports/
    │   │   │   ├── inbound/
    │   │   │   └── outbound/
    │   │   └── use_cases/
    │   ├── controllers/
    │   │   └── security/
    │   ├── adapters/
    │   │   ├── inbound/
    │   │   └── outbound/
    │   │       ├── compute/
    │   │       ├── operating_system/
    │   │       ├── backup/
    │   │       ├── network/
    │   │       ├── observability/
    │   │       ├── persistence/
    │   │       ├── policy_engine/
    │   │       └── security/
    │   └── bootstrap/
    ├── tests/
    │   ├── unit/
    │   ├── contract/
    │   └── integration/
    └── runbooks/

## Responsabilità

- `domain`: modello puro e invarianti.
- `application`: porte e casi d'uso.
- `controllers`: reconciliation loop.
- `adapters/inbound`: CLI, timer, eventi, futura API/UI.
- `adapters/outbound`: tecnologie e prodotti concreti.
- `bootstrap`: configurazione e composizione delle dipendenze.
- `tests`: unit, contract e integration.
- `security`: famiglia funzionale permanente.

## Regole immutabili

- Il dominio non importa tecnologie.
- Le tecnologie concrete esistono negli adapter.
- Le policy sono separate dall'enforcement.
- I controller invocano casi d'uso applicativi.
- Il bootstrap non contiene logica decisionale.
- Non verranno ricreati layer `provider`, `providers`, `interfaces`,
  `runtime` o `policy` sotto `src/sandra`.
- OpenVAS/Greenbone sarà un adapter Security, non il decisore.
- La struttura non cambia per preferenza, moda o intuizione.

## Ciclo operativo

    Observe
    → Reconcile
    → Evaluate Policy
    → Plan
    → Execute
    → Verify
    → Record
EOF

cat > "${FREEZE_ADR}" <<'EOF'
# ADR-0007 — Architecture GRANITA Freeze V1

## Stato

Accepted and immutable until project completion.

## Decisione

SANDRA adotta definitivamente:

- Ports and Adapters;
- controller/reconciliation pattern;
- Resource Model con apiVersion, kind, metadata, spec e status;
- separazione fra decisione di policy ed enforcement;
- dependency direction verso il dominio;
- bootstrap come composition root;
- test unitari, contrattuali e d'integrazione;
- Security come famiglia funzionale permanente.

## Prodotti concreti

- PVE e VMware: adapter compute.
- Linux e Windows: adapter operating_system.
- PBS: adapter backup.
- OpenVAS/Greenbone: adapter security.
- OPA: adapter policy_engine.
- Database: adapter persistence.

Il codice storico in `src/providers`, `src/runtime` e `src/domain`
rimane patrimonio di migrazione e non definisce la struttura canonica.
EOF

cat > "${FREEZE_VALIDATOR}" <<'PYTHON'
#!/usr/bin/env python3

from __future__ import annotations

import json
import pathlib
import sys


def fail(message: str) -> None:
    raise SystemExit(
        f"ARCHITECTURE_FREEZE_INVALID:{message}"
    )


def main() -> int:
    if len(sys.argv) != 3:
        fail("USAGE")

    contract_path = pathlib.Path(sys.argv[1]).resolve()
    root = pathlib.Path(sys.argv[2]).resolve()

    try:
        contract = json.loads(
            contract_path.read_text(encoding="utf-8")
        )
    except FileNotFoundError:
        fail("CONTRACT_MISSING")
    except json.JSONDecodeError as exc:
        fail(
            f"CONTRACT_JSON:{exc.lineno}:{exc.colno}"
        )

    if contract.get("apiVersion") != (
        "architecture.sandra.io/v1"
    ):
        fail("API_VERSION")

    if contract.get("kind") != "ArchitectureFreeze":
        fail("KIND")

    metadata = contract.get("metadata")

    if not isinstance(metadata, dict):
        fail("METADATA")

    if metadata.get("id") != "architecture-granita-v1":
        fail("IDENTIFIER")

    if metadata.get("status") != "immutable":
        fail("STATUS")

    spec = contract.get("spec")

    if not isinstance(spec, dict):
        fail("SPEC")

    expected_layers = {
        "domain",
        "application",
        "controllers",
        "adapters",
        "bootstrap",
    }

    declared_layers = set(
        spec.get("immutableLayers", [])
    )

    if declared_layers != expected_layers:
        fail("IMMUTABLE_LAYERS")

    missing_paths = [
        relative
        for relative in spec.get("requiredPaths", [])
        if not (root / relative).is_dir()
    ]

    if missing_paths:
        fail(
            "REQUIRED_PATHS_MISSING:"
            + ",".join(sorted(missing_paths))
        )

    forbidden_paths = [
        relative
        for relative in spec.get("forbiddenPaths", [])
        if (
            (root / relative).exists()
            or (root / relative).is_symlink()
        )
    ]

    if forbidden_paths:
        fail(
            "FORBIDDEN_PATHS_PRESENT:"
            + ",".join(sorted(forbidden_paths))
        )

    sandra_root = root / spec["sourceRoot"]

    actual_layers = {
        path.name
        for path in sandra_root.iterdir()
        if path.is_dir()
    }

    unexpected_layers = actual_layers - expected_layers

    if unexpected_layers:
        fail(
            "UNEXPECTED_LAYERS:"
            + ",".join(sorted(unexpected_layers))
        )

    print("ARCHITECTURE_GRANITA_FREEZE=PASS")
    print("FREEZE_ID=architecture-granita-v1")
    print("FREEZE_STATUS=IMMUTABLE")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
PYTHON

chmod 0755 "${FREEZE_VALIDATOR}"

python3 \
    "${FREEZE_VALIDATOR}" \
    "${FREEZE_CONTRACT}" \
    "${ROOT}" \
    > "${SANDRA_EVIDENCE_DIR}/architecture-freeze-validation.txt"

grep -q \
    '^ARCHITECTURE_GRANITA_FREEZE=PASS$' \
    "${SANDRA_EVIDENCE_DIR}/architecture-freeze-validation.txt"

python3 - "${MANIFEST}" <<'PYTHON'
import json
from pathlib import Path
import sys

path = Path(sys.argv[1])

manifest = json.loads(
    path.read_text(encoding="utf-8")
)

records = manifest["source_roots"]


def ensure_record(
    identifier: str,
    root: str,
    owner: str,
) -> None:
    matches = [
        record
        for record in records
        if record.get("id") == identifier
    ]

    expected = {
        "id": identifier,
        "root": root,
        "owner": owner,
    }

    if len(matches) > 1:
        raise SystemExit(
            f"DUPLICATE_SOURCE_ROOT:{identifier}"
        )

    if not matches:
        records.append(expected)
        return

    if matches[0] != expected:
        raise SystemExit(
            f"SOURCE_ROOT_CONFLICT:{identifier}"
        )


ensure_record(
    "sandra",
    "src/sandra",
    "architecture",
)

ensure_record(
    "tests",
    "tests",
    "engineering",
)

path.write_text(
    json.dumps(
        manifest,
        indent=2,
        ensure_ascii=False,
    )
    + "\n",
    encoding="utf-8",
)
PYTHON

python3 - \
    "${STATE}" \
    "${SANDRA_RUNBOOK_ID}" \
    "${SANDRA_RUN_ID}" \
    "${JOURNAL#${ROOT}/}" <<'PYTHON'
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

state["metadata"]["state_version"] = "4.0.0"
state["metadata"]["updated_utc"] = (
    datetime.datetime.now(
        datetime.timezone.utc
    )
    .replace(microsecond=0)
    .isoformat()
    .replace("+00:00", "Z")
)

state["spec"]["architecture"] = {
    "version": "4.0.0",
    "document": (
        "docs/architecture/"
        "ARCHITECTURE-FREEZE-V1.md"
    ),
    "contract": (
        "docs/architecture/"
        "ARCHITECTURE-FREEZE-V1.json"
    ),
    "validator": (
        "src/knowledge/"
        "validate_architecture_freeze.py"
    ),
    "freeze": {
        "id": "architecture-granita-v1",
        "name": "Architecture GRANITA Freeze V1",
        "status": "immutable",
        "scope": "until_project_completion",
        "ordinary_change_allowed": False,
        "preference_change_allowed": False,
        "intuition_change_allowed": False,
        "rename_allowed": False,
        "layer_movement_allowed": False
    },
    "model": "controller_reconciliation",
    "architecture_style": "ports_and_adapters",
    "resource_envelope": (
        "kubernetes_api_conventions"
    ),
    "policy_model": (
        "decision_enforcement_separation"
    ),
    "canonical_source_root": "src/sandra",
    "test_root": "tests",
    "immutable_layers": [
        "domain",
        "application",
        "controllers",
        "adapters",
        "bootstrap"
    ],
    "security": {
        "status": "permanent_functional_family",
        "controller": (
            "src/sandra/controllers/security"
        ),
        "adapter_root": (
            "src/sandra/adapters/outbound/security"
        ),
        "first_product_candidate": (
            "openvas_greenbone"
        )
    }
}

principles = state["spec"].setdefault(
    "principles",
    []
)

for principle in (
    (
        "Architecture GRANITA Freeze V1 "
        "immutabile fino alla fine del progetto"
    ),
    (
        "nessuna rinomina o movimento dei layer "
        "per preferenza o intuizione"
    ),
    (
        "Security è una famiglia funzionale "
        "permanente"
    ),
):
    if principle not in principles:
        principles.append(principle)

state["spec"]["roadmap"]["current_gate"] = {
    "runbook": "R3-000008",
    "title": "Architecture GRANITA Freeze V1",
    "type": "constitutional_architecture_freeze",
    "targets": [
        "Knowledge canonica",
        "struttura sorgente definitiva",
        "contratto architetturale",
        "validatore architetturale"
    ],
    "excluded_targets": [
        "sistemi remoti dell'Habitat",
        "installazione software"
    ],
    "objectives": [
        "congelare i confini architetturali",
        "creare lo scheletro definitivo",
        "rendere Security permanente",
        "registrare la validazione deterministica"
    ],
    "prohibitions": [
        "nessuna rinomina dei layer",
        "nessuno spostamento delle responsabilità",
        "nessun ritorno al modello provider",
        "nessun layer interfaces",
        "nessun layer runtime generico",
        "nessun layer policy separato",
        "nessuna modifica ad intuito"
    ]
}

state["spec"]["roadmap"]["next_gate"] = {
    "runbook": "R3-000009",
    "title": "Canonical Domain Migration",
    "status": "blocked"
}

state["status"]["current_certification"] = {
    "runbook": runbook_id,
    "run_id": run_id,
    "journal": journal
}

state["status"]["roadmap"] = {
    "phase": "Architecture GRANITA Freeze V1",
    "current_gate": "R3-000008",
    "current_gate_status": "complete",
    "next_gate": "R3-000009"
}

state["status"]["architecture_granita_freeze_v1"] = {
    "runbook": runbook_id,
    "run_id": run_id,
    "status": "certified_immutable",
    "contract_validation": "pass",
    "canonical_source_root": "src/sandra",
    "security_family": "permanent",
    "software_installed": "none",
    "remote_habitat_modifications": "none"
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
# ${SANDRA_RUNBOOK_ID} — Architecture GRANITA Freeze V1

- Run ID: \`${SANDRA_RUN_ID}\`
- Architecture status: \`IMMUTABLE\`
- Scope: \`UNTIL PROJECT COMPLETION\`
- Remote Habitat modifications: \`NONE\`
- Software installed: \`NONE\`

## Result

- registered Architecture GRANITA Freeze V1;
- created the permanent skeleton under \`src/sandra\`;
- registered unit, contract and integration test roots;
- made Security a permanent functional family;
- added the machine-readable contract;
- added deterministic architecture validation;
- updated STATE and Knowledge manifest.
EOF

knowledge_validate
knowledge_generate_views
knowledge_continuity_validate

knowledge_sync \
    "${SANDRA_RUNBOOK_ID}: register Architecture GRANITA Freeze V1"

sandra_assert knowledge_verify_remote
sandra_assert knowledge_validate
sandra_assert knowledge_continuity_validate

python3 \
    "${FREEZE_VALIDATOR}" \
    "${FREEZE_CONTRACT}" \
    "${ROOT}" \
    > "${SANDRA_EVIDENCE_DIR}/architecture-freeze-postcheck.txt"

grep -q \
    '^ARCHITECTURE_GRANITA_FREEZE=PASS$' \
    "${SANDRA_EVIDENCE_DIR}/architecture-freeze-postcheck.txt"

{
    printf 'ARCHITECTURE_FREEZE=PASS\n'
    printf 'FREEZE_NAME=GRANITA\n'
    printf 'FREEZE_ID=architecture-granita-v1\n'
    printf 'FREEZE_STATUS=IMMUTABLE\n'
    printf 'FREEZE_SCOPE=UNTIL_PROJECT_COMPLETION\n'
    printf 'CANONICAL_SOURCE_ROOT=src/sandra\n'
    printf 'SECURITY_FAMILY=PERMANENT\n'
    printf 'STATE_SHA256=%s\n' \
        "$(sha256sum "${STATE}" | awk '{print $1}')"
    printf 'CONTRACT_SHA256=%s\n' \
        "$(sha256sum "${FREEZE_CONTRACT}" | awk '{print $1}')"
    printf 'GIT_HEAD=%s\n' \
        "$(git -C "${ROOT}" rev-parse HEAD)"
    printf 'GIT_ORIGIN_MAIN=%s\n' \
        "$(git -C "${ROOT}" rev-parse origin/main)"
    printf 'REMOTE_HABITAT_MODIFICATIONS=NONE\n'
    printf 'SOFTWARE_INSTALLED=NONE\n'
} > "${SANDRA_EVIDENCE_DIR}/result.env"

sandra_end PASS
