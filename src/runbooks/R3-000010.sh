#!/usr/bin/env bash

source /opt/sandra/core/core.sh
source /opt/sandra/knowledge/knowledge.sh

set -Eeuo pipefail
umask 077

export SANDRA_RUNBOOK_SOURCE="/root/R3-000010-application-ports-foundation.sh"

sandra_begin \
    "R3-000010" \
    "Establish canonical Application Ports Foundation"

for command_name in \
    python3 git install cp grep find sha256sum
do
    sandra_require_command "${command_name}"
done

ROOT="${SANDRA_KNOWLEDGE_ROOT}"
STATE="${ROOT}/STATE.json"

APPLICATION_ROOT="${ROOT}/src/sandra/application"
PORTS_ROOT="${APPLICATION_ROOT}/ports"
INBOUND_ROOT="${PORTS_ROOT}/inbound"
OUTBOUND_ROOT="${PORTS_ROOT}/outbound"
USE_CASES_ROOT="${APPLICATION_ROOT}/use_cases"

TEST_ROOT="${ROOT}/tests/contract/application"
VALIDATOR="${ROOT}/src/knowledge/validate_application_foundation.py"
CONTRACT_DOC="${ROOT}/docs/contracts/application/APPLICATION-PORTS-FOUNDATION-V1.json"
ADR="${ROOT}/docs/adr/ADR-0010-APPLICATION-PORTS-FOUNDATION.md"

ARCH_CONTRACT="${ROOT}/docs/architecture/ARCHITECTURE-CONSTITUTION-V1.json"
ARCH_VALIDATOR="${ROOT}/src/knowledge/validate_architecture_constitution.py"

CAPABILITY_MAP="${ROOT}/docs/capabilities/CANONICAL-CAPABILITY-MAP-V1.json"
CAPABILITY_VALIDATOR="${ROOT}/src/knowledge/validate_capability_map.py"

CONSTITUTIONAL_INDEX="${ROOT}/docs/contracts/constitutional/CONSTITUTIONAL-CONTRACTS-V1.json"
CONSTITUTIONAL_VALIDATOR="${ROOT}/src/knowledge/validate_constitutional_contracts.py"

BACKUP_ROOT="${SANDRA_RUN_DIR}/backups"
JOURNAL="$(knowledge_journal_path)"
RUNBOOK_DEST="${ROOT}/src/runbooks/${SANDRA_RUNBOOK_ID}.sh"

for required_file in \
    "${STATE}" \
    "${ARCH_CONTRACT}" \
    "${ARCH_VALIDATOR}" \
    "${CAPABILITY_MAP}" \
    "${CAPABILITY_VALIDATOR}" \
    "${CONSTITUTIONAL_INDEX}" \
    "${CONSTITUTIONAL_VALIDATOR}"
do
    sandra_require_file "${required_file}"
done

for required_directory in \
    "${APPLICATION_ROOT}" \
    "${INBOUND_ROOT}" \
    "${OUTBOUND_ROOT}" \
    "${USE_CASES_ROOT}"
do
    if [[ ! -d "${required_directory}" ]]; then
        sandra_fail \
            "Canonical Application directory missing: ${required_directory}"
    fi
done

git -C "${ROOT}" diff --quiet
git -C "${ROOT}" diff --cached --quiet

mapfile -t PREEXISTING_APPLICATION_FILES < <(
    find "${APPLICATION_ROOT}" \
        -type f \
        -print \
        | sort
)

if [[ "${#PREEXISTING_APPLICATION_FILES[@]}" -ne 0 ]]; then
    printf '%s\n' \
        "${PREEXISTING_APPLICATION_FILES[@]}" \
        > "${SANDRA_EVIDENCE_DIR}/unexpected-application-files.txt"

    sandra_fail \
        "Application Layer is not empty before foundation gate"
fi

for target in \
    "${VALIDATOR}" \
    "${CONTRACT_DOC}" \
    "${ADR}"
do
    if [[ -e "${target}" || -L "${target}" ]]; then
        sandra_fail \
            "Application foundation target already exists: ${target}"
    fi
done

install -d -m 0700 \
    "${BACKUP_ROOT}"

cp -a -- \
    "${STATE}" \
    "${BACKUP_ROOT}/STATE.json.before"

install -d -m 0755 \
    "${APPLICATION_ROOT}" \
    "${PORTS_ROOT}" \
    "${INBOUND_ROOT}" \
    "${OUTBOUND_ROOT}" \
    "${USE_CASES_ROOT}" \
    "${TEST_ROOT}" \
    "$(dirname "${VALIDATOR}")" \
    "$(dirname "${CONTRACT_DOC}")" \
    "$(dirname "${ADR}")" \
    "$(dirname "${JOURNAL}")" \
    "$(dirname "${RUNBOOK_DEST}")"

python3 \
    "${ARCH_VALIDATOR}" \
    "${ARCH_CONTRACT}" \
    "${ROOT}" \
    > "${SANDRA_EVIDENCE_DIR}/architecture-precheck.txt"

grep -q \
    '^ARCHITECTURE_CONSTITUTION=PASS$' \
    "${SANDRA_EVIDENCE_DIR}/architecture-precheck.txt"

python3 \
    "${CONSTITUTIONAL_VALIDATOR}" \
    "${ROOT}" \
    "${CONSTITUTIONAL_INDEX}" \
    "${ARCH_CONTRACT}" \
    > "${SANDRA_EVIDENCE_DIR}/constitutional-contracts-precheck.txt"

grep -q \
    '^CONSTITUTIONAL_CONTRACTS=PASS$' \
    "${SANDRA_EVIDENCE_DIR}/constitutional-contracts-precheck.txt"

python3 \
    "${CAPABILITY_VALIDATOR}" \
    "${CAPABILITY_MAP}" \
    "${ARCH_CONTRACT}" \
    "${CONSTITUTIONAL_INDEX}" \
    > "${SANDRA_EVIDENCE_DIR}/capability-map-precheck.txt"

grep -q \
    '^CANONICAL_CAPABILITY_MAP_VALIDATOR=PASS$' \
    "${SANDRA_EVIDENCE_DIR}/capability-map-precheck.txt"

cat > "${APPLICATION_ROOT}/__init__.py" <<'PYTHON'
"""Canonical SANDRA Application Layer."""

from .errors import (
    ApplicationConflictError,
    ApplicationError,
    ApplicationPreconditionError,
    ApplicationValidationError,
)
from .messages import ApplicationMessage, Command, Query
from .result import ApplicationResult

__all__ = [
    "ApplicationConflictError",
    "ApplicationError",
    "ApplicationMessage",
    "ApplicationPreconditionError",
    "ApplicationResult",
    "ApplicationValidationError",
    "Command",
    "Query",
]
PYTHON

cat > "${APPLICATION_ROOT}/errors.py" <<'PYTHON'
"""Technology-independent Application Layer errors."""

from __future__ import annotations


class ApplicationError(Exception):
    """Base error for Application Layer failures."""


class ApplicationValidationError(ApplicationError):
    """Input message or use-case contract is invalid."""


class ApplicationPreconditionError(ApplicationError):
    """A required precondition was not satisfied."""


class ApplicationConflictError(ApplicationError):
    """The request conflicts with a newer or concurrent state."""
PYTHON

cat > "${APPLICATION_ROOT}/messages.py" <<'PYTHON'
"""Application messages shared by inbound ports and use cases."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone


@dataclass(frozen=True, slots=True)
class ApplicationMessage:
    """Base immutable message crossing an inbound Application port."""

    message_id: str
    correlation_id: str
    created_at: datetime

    def __post_init__(self) -> None:
        if not self.message_id:
            raise ValueError("message_id must not be empty")

        if not self.correlation_id:
            raise ValueError("correlation_id must not be empty")

        if self.created_at.tzinfo is None:
            raise ValueError("created_at must be timezone-aware")

    @classmethod
    def timestamp_now(cls) -> datetime:
        """Return an aware UTC timestamp for message construction."""

        return datetime.now(timezone.utc)


@dataclass(frozen=True, slots=True)
class Command(ApplicationMessage):
    """Message requesting an authorized state-changing use case."""


@dataclass(frozen=True, slots=True)
class Query(ApplicationMessage):
    """Message requesting a non-mutating use case."""
PYTHON

cat > "${APPLICATION_ROOT}/result.py" <<'PYTHON'
"""Deterministic Application Layer result envelope."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Generic, TypeVar


ResultValue = TypeVar("ResultValue")


@dataclass(frozen=True, slots=True)
class ApplicationResult(Generic[ResultValue]):
    """Result returned by an inbound Application port."""

    success: bool
    code: str
    value: ResultValue | None = None
    error: str | None = None

    def __post_init__(self) -> None:
        if not self.code:
            raise ValueError("code must not be empty")

        if self.success and self.error is not None:
            raise ValueError(
                "successful result cannot contain an error"
            )

        if not self.success and not self.error:
            raise ValueError(
                "failed result must contain an error"
            )

    @classmethod
    def ok(
        cls,
        code: str,
        value: ResultValue | None = None,
    ) -> "ApplicationResult[ResultValue]":
        """Create a successful result."""

        return cls(
            success=True,
            code=code,
            value=value,
        )

    @classmethod
    def fail(
        cls,
        code: str,
        error: str,
    ) -> "ApplicationResult[ResultValue]":
        """Create a failed result."""

        return cls(
            success=False,
            code=code,
            error=error,
        )
PYTHON

cat > "${PORTS_ROOT}/__init__.py" <<'PYTHON'
"""Canonical inbound and outbound Application ports."""
PYTHON

cat > "${INBOUND_ROOT}/__init__.py" <<'PYTHON'
"""Inbound ports driving SANDRA use cases."""

from .command import CommandHandler
from .query import QueryHandler

__all__ = [
    "CommandHandler",
    "QueryHandler",
]
PYTHON

cat > "${INBOUND_ROOT}/command.py" <<'PYTHON'
"""Inbound command port contract."""

from __future__ import annotations

from typing import Protocol, TypeVar

from application.messages import Command
from application.result import ApplicationResult


CommandType = TypeVar(
    "CommandType",
    bound=Command,
    contravariant=True,
)
CommandResult = TypeVar(
    "CommandResult",
    covariant=True,
)


class CommandHandler(
    Protocol[CommandType, CommandResult]
):
    """Handle one technology-independent command."""

    def handle(
        self,
        command: CommandType,
    ) -> ApplicationResult[CommandResult]:
        """Execute the command use case."""
        ...
PYTHON

cat > "${INBOUND_ROOT}/query.py" <<'PYTHON'
"""Inbound query port contract."""

from __future__ import annotations

from typing import Protocol, TypeVar

from application.messages import Query
from application.result import ApplicationResult


QueryType = TypeVar(
    "QueryType",
    bound=Query,
    contravariant=True,
)
QueryResult = TypeVar(
    "QueryResult",
    covariant=True,
)


class QueryHandler(
    Protocol[QueryType, QueryResult]
):
    """Handle one technology-independent query."""

    def handle(
        self,
        query: QueryType,
    ) -> ApplicationResult[QueryResult]:
        """Execute the query use case."""
        ...
PYTHON

cat > "${OUTBOUND_ROOT}/__init__.py" <<'PYTHON'
"""Outbound ports implemented by technology adapters."""

from .event_bus import EventBus
from .repository import Repository
from .unit_of_work import UnitOfWork

__all__ = [
    "EventBus",
    "Repository",
    "UnitOfWork",
]
PYTHON

cat > "${OUTBOUND_ROOT}/repository.py" <<'PYTHON'
"""Technology-independent persistence port."""

from __future__ import annotations

from typing import Protocol, TypeVar


Entity = TypeVar("Entity")
Identity = TypeVar("Identity")


class Repository(
    Protocol[Identity, Entity]
):
    """Load and persist one category of application entity."""

    def get(
        self,
        identifier: Identity,
    ) -> Entity | None:
        """Return the entity or None when it does not exist."""
        ...

    def save(
        self,
        entity: Entity,
    ) -> None:
        """Persist the supplied entity."""
        ...
PYTHON

cat > "${OUTBOUND_ROOT}/event_bus.py" <<'PYTHON'
"""Technology-independent event publication port."""

from __future__ import annotations

from typing import Protocol, TypeVar


Event = TypeVar("Event", contravariant=True)


class EventBus(Protocol[Event]):
    """Publish immutable application or domain events."""

    def publish(
        self,
        event: Event,
    ) -> None:
        """Publish one event."""
        ...
PYTHON

cat > "${OUTBOUND_ROOT}/unit_of_work.py" <<'PYTHON'
"""Application transaction-boundary port."""

from __future__ import annotations

from types import TracebackType
from typing import Protocol, Self


class UnitOfWork(Protocol):
    """Control one atomic Application Layer consistency boundary."""

    def __enter__(self) -> Self:
        """Enter the consistency boundary."""
        ...

    def __exit__(
        self,
        exception_type: type[BaseException] | None,
        exception: BaseException | None,
        traceback: TracebackType | None,
    ) -> bool | None:
        """Close the boundary and preserve exception semantics."""
        ...

    def commit(self) -> None:
        """Commit all pending authoritative changes."""
        ...

    def rollback(self) -> None:
        """Discard all pending authoritative changes."""
        ...
PYTHON

cat > "${USE_CASES_ROOT}/__init__.py" <<'PYTHON'
"""Application use-case contracts.

Concrete use cases are intentionally absent from R3-000010.
"""

from .contract import UseCase

__all__ = [
    "UseCase",
]
PYTHON

cat > "${USE_CASES_ROOT}/contract.py" <<'PYTHON'
"""Generic technology-independent use-case contract."""

from __future__ import annotations

from typing import Protocol, TypeVar


Request = TypeVar(
    "Request",
    contravariant=True,
)
Response = TypeVar(
    "Response",
    covariant=True,
)


class UseCase(
    Protocol[Request, Response]
):
    """Execute one bounded Application Layer responsibility."""

    def execute(
        self,
        request: Request,
    ) -> Response:
        """Execute the use case."""
        ...
PYTHON

cat > "${CONTRACT_DOC}" <<'EOF'
{
  "apiVersion": "application.sandra.io/v1",
  "kind": "ApplicationPortsFoundation",
  "metadata": {
    "id": "application-ports-foundation-v1",
    "name": "SANDRA Application Ports Foundation V1",
    "status": "immutable"
  },
  "spec": {
    "root": "src/sandra/application",
    "inboundPorts": [
      "CommandHandler",
      "QueryHandler"
    ],
    "outboundPorts": [
      "Repository",
      "EventBus",
      "UnitOfWork"
    ],
    "applicationTypes": [
      "ApplicationMessage",
      "Command",
      "Query",
      "ApplicationResult",
      "ApplicationError"
    ],
    "useCaseContract": "UseCase",
    "rules": [
      "application ports are technology-independent",
      "inbound ports drive use cases",
      "outbound ports are implemented by adapters",
      "the application layer may depend on domain contracts",
      "the application layer must not import controllers adapters or bootstrap",
      "concrete products and transports are forbidden",
      "concrete use cases are outside the scope of this foundation gate"
    ],
    "forbiddenTerms": [
      "proxmox",
      "pve",
      "vmware",
      "linux",
      "windows",
      "pbs",
      "openvas",
      "greenbone",
      "opa",
      "ssh",
      "winrm",
      "telegram",
      "prometheus",
      "alertmanager",
      "nmap",
      "ansible"
    ]
  }
}
EOF

cat > "${ADR}" <<'EOF'
# ADR-0010 — Application Ports Foundation V1

## Stato

Accepted and immutable.

## Decisione

SANDRA adotta una fondazione applicativa composta da:

- messaggi immutabili `Command` e `Query`;
- result envelope deterministico;
- inbound port `CommandHandler`;
- inbound port `QueryHandler`;
- outbound port `Repository`;
- outbound port `EventBus`;
- outbound port `UnitOfWork`;
- contratto generico `UseCase`.

## Confini

Il gate non introduce:

- use case concreti;
- controller;
- adapter outbound;
- prodotti;
- trasporti;
- logica infrastrutturale.

## Dipendenze

L'Application Layer può dipendere dal Domain.

Domain non dipende da Application.

Application non dipende da Controller, Adapter o Bootstrap.
EOF

cat > "${VALIDATOR}" <<'PYTHON'
#!/usr/bin/env python3

from __future__ import annotations

import ast
import json
from pathlib import Path
import re
import sys
from typing import Any, NoReturn


EXPECTED_FILES = {
    "__init__.py",
    "errors.py",
    "messages.py",
    "result.py",
    "ports/__init__.py",
    "ports/inbound/__init__.py",
    "ports/inbound/command.py",
    "ports/inbound/query.py",
    "ports/outbound/__init__.py",
    "ports/outbound/repository.py",
    "ports/outbound/event_bus.py",
    "ports/outbound/unit_of_work.py",
    "use_cases/__init__.py",
    "use_cases/contract.py",
}

FORBIDDEN_IMPORT_ROOTS = {
    "controllers",
    "adapters",
    "bootstrap",
}

FORBIDDEN_WORDS = {
    "proxmox",
    "pve",
    "vmware",
    "linux",
    "windows",
    "pbs",
    "openvas",
    "greenbone",
    "opa",
    "ssh",
    "winrm",
    "telegram",
    "prometheus",
    "alertmanager",
    "nmap",
    "ansible",
}


def fail(message: str) -> NoReturn:
    raise SystemExit(
        f"APPLICATION_FOUNDATION_INVALID:{message}"
    )


def load_json(path: Path) -> dict[str, Any]:
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


def imported_roots(tree: ast.AST) -> set[str]:
    roots: set[str] = set()

    for node in ast.walk(tree):
        if isinstance(node, ast.Import):
            roots.update(
                alias.name.split(".", 1)[0]
                for alias in node.names
            )
        elif isinstance(node, ast.ImportFrom):
            if node.module:
                roots.add(
                    node.module.split(".", 1)[0]
                )

    return roots


def main() -> int:
    if len(sys.argv) != 4:
        fail("USAGE")

    application_root = Path(sys.argv[1]).resolve()
    contract_path = Path(sys.argv[2]).resolve()
    capability_path = Path(sys.argv[3]).resolve()

    contract = load_json(contract_path)
    capability = load_json(capability_path)

    if contract.get("kind") != (
        "ApplicationPortsFoundation"
    ):
        fail("CONTRACT_KIND")

    if (
        contract.get("metadata", {}).get("id")
        != "application-ports-foundation-v1"
    ):
        fail("CONTRACT_ID")

    if (
        contract.get("metadata", {}).get("status")
        != "immutable"
    ):
        fail("CONTRACT_STATUS")

    if (
        capability.get("metadata", {}).get("id")
        != "canonical-capability-map-v1"
    ):
        fail("CAPABILITY_MAP_ID")

    if (
        capability.get("metadata", {}).get("status")
        != "immutable"
    ):
        fail("CAPABILITY_MAP_STATUS")

    actual_files = {
        path.relative_to(application_root).as_posix()
        for path in application_root.rglob("*.py")
        if "__pycache__" not in path.parts
    }

    if actual_files != EXPECTED_FILES:
        missing = sorted(
            EXPECTED_FILES - actual_files
        )
        unexpected = sorted(
            actual_files - EXPECTED_FILES
        )

        fail(
            "FILE_SET:"
            f"MISSING={missing}:"
            f"UNEXPECTED={unexpected}"
        )

    violations: list[str] = []

    for path in sorted(
        application_root.rglob("*.py")
    ):
        if "__pycache__" in path.parts:
            continue

        source = path.read_text(
            encoding="utf-8"
        )

        tree = ast.parse(
            source,
            filename=str(path),
        )

        forbidden_imports = sorted(
            imported_roots(tree)
            & FORBIDDEN_IMPORT_ROOTS
        )

        if forbidden_imports:
            violations.append(
                f"{path.name}:IMPORT:"
                + ",".join(forbidden_imports)
            )

        words = set(
            re.findall(
                r"[a-z0-9_]+",
                source.lower(),
            )
        )

        forbidden_words = sorted(
            words & FORBIDDEN_WORDS
        )

        if forbidden_words:
            violations.append(
                f"{path.name}:PRODUCT:"
                + ",".join(forbidden_words)
            )

    if violations:
        fail(
            "VIOLATIONS:"
            + "|".join(violations)
        )

    print("APPLICATION_PORTS_FOUNDATION=PASS")
    print("APPLICATION_PYTHON_FILE_COUNT=14")
    print("INBOUND_PORT_COUNT=2")
    print("OUTBOUND_PORT_COUNT=3")
    print("CONCRETE_USE_CASE_COUNT=0")
    print("PRODUCT_TERMS=NONE")
    print("OUTER_LAYER_IMPORTS=NONE")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
PYTHON

chmod 0755 "${VALIDATOR}"

cat > "${TEST_ROOT}/__init__.py" <<'PYTHON'
"""Application contract tests."""
PYTHON

cat > "${TEST_ROOT}/test_application_foundation.py" <<'PYTHON'
from __future__ import annotations

from datetime import datetime, timezone
import unittest

from application.messages import Command, Query
from application.result import ApplicationResult
from application.ports.inbound import (
    CommandHandler,
    QueryHandler,
)
from application.ports.outbound import (
    EventBus,
    Repository,
    UnitOfWork,
)
from application.use_cases import UseCase


class ApplicationFoundationTests(
    unittest.TestCase
):
    def test_command_is_immutable_message(self) -> None:
        command = Command(
            message_id="message-1",
            correlation_id="correlation-1",
            created_at=datetime.now(timezone.utc),
        )

        self.assertEqual(
            command.message_id,
            "message-1",
        )

        with self.assertRaises(
            AttributeError
        ):
            command.message_id = "changed"  # type: ignore[misc]

    def test_query_requires_aware_timestamp(self) -> None:
        with self.assertRaises(
            ValueError
        ):
            Query(
                message_id="message-2",
                correlation_id="correlation-2",
                created_at=datetime.now(),
            )

    def test_success_result_rejects_error(self) -> None:
        with self.assertRaises(
            ValueError
        ):
            ApplicationResult[
                str
            ](
                success=True,
                code="OK",
                value="value",
                error="unexpected",
            )

    def test_failed_result_requires_error(self) -> None:
        with self.assertRaises(
            ValueError
        ):
            ApplicationResult[
                str
            ](
                success=False,
                code="FAILED",
            )

    def test_protocols_are_importable(self) -> None:
        self.assertIsNotNone(CommandHandler)
        self.assertIsNotNone(QueryHandler)
        self.assertIsNotNone(Repository)
        self.assertIsNotNone(EventBus)
        self.assertIsNotNone(UnitOfWork)
        self.assertIsNotNone(UseCase)


if __name__ == "__main__":
    unittest.main()
PYTHON

python3 -m compileall \
    -q \
    "${APPLICATION_ROOT}" \
    "${TEST_ROOT}" \
    "${VALIDATOR}"

python3 \
    "${VALIDATOR}" \
    "${APPLICATION_ROOT}" \
    "${CONTRACT_DOC}" \
    "${CAPABILITY_MAP}" \
    > "${SANDRA_EVIDENCE_DIR}/application-foundation-validation.txt"

grep -q \
    '^APPLICATION_PORTS_FOUNDATION=PASS$' \
    "${SANDRA_EVIDENCE_DIR}/application-foundation-validation.txt"

PYTHONPATH="${ROOT}/src/sandra" \
python3 -m unittest discover \
    -s "${TEST_ROOT}" \
    -p 'test_*.py' \
    -v \
    > "${SANDRA_EVIDENCE_DIR}/application-contract-tests.txt" \
    2>&1

find "${APPLICATION_ROOT}" "${TEST_ROOT}" \
    -type d \
    -name '__pycache__' \
    -prune \
    -exec rm -rf -- {} +

find "${APPLICATION_ROOT}" "${TEST_ROOT}" \
    -type f \
    -name '*.pyc' \
    -delete

python3 \
    "${ARCH_VALIDATOR}" \
    "${ARCH_CONTRACT}" \
    "${ROOT}" \
    > "${SANDRA_EVIDENCE_DIR}/architecture-postcheck.txt"

grep -q \
    '^ARCHITECTURE_CONSTITUTION=PASS$' \
    "${SANDRA_EVIDENCE_DIR}/architecture-postcheck.txt"

python3 \
    "${CAPABILITY_VALIDATOR}" \
    "${CAPABILITY_MAP}" \
    "${ARCH_CONTRACT}" \
    "${CONSTITUTIONAL_INDEX}" \
    > "${SANDRA_EVIDENCE_DIR}/capability-map-postcheck.txt"

grep -q \
    '^CANONICAL_CAPABILITY_MAP_VALIDATOR=PASS$' \
    "${SANDRA_EVIDENCE_DIR}/capability-map-postcheck.txt"

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

capability_map = state["spec"].get(
    "capability_map"
)

if not isinstance(capability_map, dict):
    raise SystemExit(
        "CAPABILITY_MAP_STATE_MISSING"
    )

if capability_map.get("status") != "immutable":
    raise SystemExit(
        "CAPABILITY_MAP_NOT_IMMUTABLE"
    )

domain_purity = state["spec"].get(
    "domain_purity"
)

if not isinstance(domain_purity, dict):
    raise SystemExit(
        "DOMAIN_PURITY_STATE_MISSING"
    )

if domain_purity.get("status") != "certified":
    raise SystemExit(
        "DOMAIN_PURITY_NOT_CERTIFIED"
    )

state["metadata"]["state_version"] = "5.0.0"
state["metadata"]["updated_utc"] = (
    datetime.datetime.now(
        datetime.timezone.utc
    )
    .replace(microsecond=0)
    .isoformat()
    .replace("+00:00", "Z")
)

state["spec"]["application_foundation"] = {
    "version": "1.0.0",
    "id": "application-ports-foundation-v1",
    "status": "certified_immutable",
    "root": "src/sandra/application",
    "contract": (
        "docs/contracts/application/"
        "APPLICATION-PORTS-FOUNDATION-V1.json"
    ),
    "validator": (
        "src/knowledge/"
        "validate_application_foundation.py"
    ),
    "inbound_ports": [
        "CommandHandler",
        "QueryHandler",
    ],
    "outbound_ports": [
        "Repository",
        "EventBus",
        "UnitOfWork",
    ],
    "application_types": [
        "ApplicationMessage",
        "Command",
        "Query",
        "ApplicationResult",
        "ApplicationError",
    ],
    "use_case_contract": "UseCase",
    "concrete_use_cases": 0,
}

roadmap = state["spec"]["roadmap"]

roadmap["current_gate"] = {
    "runbook": "R3-000010",
    "title": "Application Ports Foundation",
    "type": "application_contract_foundation",
    "targets": [
        "src/sandra/application",
        "tests/contract/application",
        (
            "docs/contracts/application/"
            "APPLICATION-PORTS-FOUNDATION-V1.json"
        ),
        "STATE.json",
    ],
    "excluded_targets": [
        "concrete use cases",
        "controllers",
        "outbound adapters",
        "remote Habitat",
        "software installation",
    ],
    "objectives": [
        "establish technology-independent application messages",
        "establish inbound command and query ports",
        "establish outbound persistence event and unit-of-work ports",
        "certify dependency direction",
    ],
    "prohibitions": [
        "no product-specific application contract",
        "no controller dependency",
        "no adapter dependency",
        "no bootstrap dependency",
        "no Habitat modification",
        "no software installation",
    ],
}

roadmap["next_gate"] = {
    "runbook": "R3-000011",
    "title": "Observation Use Case Foundation",
    "status": "blocked",
}

state["status"]["current_certification"] = {
    "runbook": runbook_id,
    "run_id": run_id,
    "journal": journal,
}

state["status"]["roadmap"] = {
    "phase": "Application Ports Foundation",
    "current_gate": "R3-000010",
    "current_gate_status": "complete",
    "next_gate": "R3-000011",
}

state["status"]["application_ports_foundation_v1"] = {
    "runbook": runbook_id,
    "run_id": run_id,
    "status": "certified_immutable",
    "python_file_count": 14,
    "inbound_port_count": 2,
    "outbound_port_count": 3,
    "concrete_use_case_count": 0,
    "contract_tests": "pass",
    "architecture_validation": "pass",
    "capability_map_validation": "pass",
    "outer_layer_imports": "none",
    "product_terms": "none",
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
# ${SANDRA_RUNBOOK_ID} — Application Ports Foundation

- Run ID: \`${SANDRA_RUN_ID}\`
- Inbound ports: \`2\`
- Outbound ports: \`3\`
- Concrete use cases: \`0\`
- Product terms: \`NONE\`
- Outer-layer imports: \`NONE\`
- Remote Habitat modifications: \`NONE\`
- Software installed: \`NONE\`

## Result

- established immutable Command and Query messages;
- established deterministic ApplicationResult;
- established CommandHandler and QueryHandler inbound ports;
- established Repository, EventBus and UnitOfWork outbound ports;
- established the generic UseCase contract;
- added contract tests and architectural validation;
- introduced no concrete use cases or technology adapters.
EOF

knowledge_validate
knowledge_generate_views
knowledge_continuity_validate

knowledge_sync \
    "${SANDRA_RUNBOOK_ID}: establish Application Ports Foundation"

sandra_assert knowledge_verify_remote
sandra_assert knowledge_validate
sandra_assert knowledge_continuity_validate

python3 \
    "${VALIDATOR}" \
    "${APPLICATION_ROOT}" \
    "${CONTRACT_DOC}" \
    "${CAPABILITY_MAP}" \
    > "${SANDRA_EVIDENCE_DIR}/application-foundation-post-sync.txt"

grep -q \
    '^APPLICATION_PORTS_FOUNDATION=PASS$' \
    "${SANDRA_EVIDENCE_DIR}/application-foundation-post-sync.txt"

python3 - \
    "${ROOT}" \
    "${SANDRA_EVIDENCE_DIR}/repository-post-sync.txt" <<'PYTHON'
from __future__ import annotations

from pathlib import Path
import subprocess
import sys

root = Path(sys.argv[1])
evidence_path = Path(sys.argv[2])

status = subprocess.run(
    [
        "git",
        "-C",
        str(root),
        "status",
        "--porcelain",
    ],
    check=True,
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE,
    text=True,
).stdout

head = subprocess.run(
    [
        "git",
        "-C",
        str(root),
        "rev-parse",
        "HEAD",
    ],
    check=True,
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE,
    text=True,
).stdout.strip()

origin = subprocess.run(
    [
        "git",
        "-C",
        str(root),
        "rev-parse",
        "origin/main",
    ],
    check=True,
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE,
    text=True,
).stdout.strip()

checks = {
    "working_tree_clean": not status.strip(),
    "head_matches_origin": head == origin,
}

evidence_path.write_text(
    "\n".join(
        f"{name}={'PASS' if passed else 'FAIL'}"
        for name, passed in sorted(checks.items())
    )
    + f"\nHEAD={head}\n"
    + f"ORIGIN_MAIN={origin}\n",
    encoding="utf-8",
)

failed = [
    name
    for name, passed in checks.items()
    if not passed
]

if failed:
    raise SystemExit(
        "REPOSITORY_POST_SYNC_FAILED:"
        + ",".join(failed)
    )

print("REPOSITORY_POST_SYNC=PASS")
PYTHON

{
    printf 'APPLICATION_PORTS_FOUNDATION=PASS\n'
    printf 'APPLICATION_FOUNDATION_ID=application-ports-foundation-v1\n'
    printf 'APPLICATION_FOUNDATION_STATUS=CERTIFIED_IMMUTABLE\n'
    printf 'APPLICATION_PYTHON_FILE_COUNT=14\n'
    printf 'INBOUND_PORT_COUNT=2\n'
    printf 'OUTBOUND_PORT_COUNT=3\n'
    printf 'CONCRETE_USE_CASE_COUNT=0\n'
    printf 'CONTRACT_TESTS=PASS\n'
    printf 'PRODUCT_TERMS=NONE\n'
    printf 'OUTER_LAYER_IMPORTS=NONE\n'
    printf 'STATE_SHA256=%s\n' \
        "$(sha256sum "${STATE}" | awk '{print $1}')"
    printf 'CONTRACT_SHA256=%s\n' \
        "$(sha256sum "${CONTRACT_DOC}" | awk '{print $1}')"
    printf 'GIT_HEAD=%s\n' \
        "$(git -C "${ROOT}" rev-parse HEAD)"
    printf 'GIT_ORIGIN_MAIN=%s\n' \
        "$(git -C "${ROOT}" rev-parse origin/main)"
    printf 'REMOTE_HABITAT_MODIFICATIONS=NONE\n'
    printf 'SOFTWARE_INSTALLED=NONE\n'
} > "${SANDRA_EVIDENCE_DIR}/result.env"

sandra_end PASS
