#!/usr/bin/env python3

from __future__ import annotations

import json
from pathlib import Path
import re
import sys
from typing import Any, NoReturn


EXPECTED_CORE = {
    "identity",
    "resource_lifecycle",
    "observation",
    "evidence_qualification",
    "resource_graph",
    "capability_declaration",
    "desired_state",
    "policy_decision",
    "planning",
    "execution",
    "verification",
    "persistence",
    "audit",
    "notification",
    "security_governance",
    "experience_learning",
}

EXPECTED_FAMILIES = {
    "compute",
    "operating_system",
    "storage",
    "backup",
    "network",
    "observability",
    "security",
    "policy_engine",
}

FORBIDDEN_CORE_TERMS = {
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

REQUIRED_PRINCIPLES = {
    "capabilities describe stable governance responsibilities",
    "core capabilities never identify products or transports",
    "products implement capabilities through outbound adapters",
    "controllers reconcile one bounded governance concern",
    "policy decision remains separate from enforcement",
    "observed data becomes authoritative only after qualification",
    "execution succeeds only after postcondition verification",
    "learning cannot bypass policy authority or safety contracts",
    "Habitat survival overrides local service optimization",
}

REQUIRED_EXTENSION_RULES = {
    "a new product adds an adapter and not a core capability",
    "a new transport adds an adapter implementation and not a domain concept",
    "a new core capability requires a superseding ADR and explicit approval",
    "operational families may gain products without changing the core map",
    "core capabilities cannot name concrete products",
    "learning remains subject to policy authority and execution safety",
}


def fail(message: str) -> NoReturn:
    raise SystemExit(
        f"CAPABILITY_MAP_INVALID:{message}"
    )


def load_json(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(
            path.read_text(encoding="utf-8")
        )
    except FileNotFoundError:
        fail(f"MISSING:{path}")
    except json.JSONDecodeError as exc:
        fail(
            f"JSON:{path}:{exc.lineno}:{exc.colno}"
        )

    if not isinstance(value, dict):
        fail(f"ROOT_NOT_OBJECT:{path}")

    return value


def require_string(
    value: Any,
    field: str,
) -> str:
    if not isinstance(value, str) or not value:
        fail(f"INVALID_STRING:{field}")

    return value


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


def require_records_by_id(
    value: Any,
    field: str,
) -> dict[str, dict[str, Any]]:
    if not isinstance(value, list) or not value:
        fail(f"INVALID_LIST:{field}")

    records: dict[str, dict[str, Any]] = {}

    for item in value:
        if not isinstance(item, dict):
            fail(f"INVALID_RECORD:{field}")

        identifier = require_string(
            item.get("id"),
            f"{field}.id",
        )

        if identifier in records:
            fail(
                f"DUPLICATE_ID:{field}:{identifier}"
            )

        records[identifier] = item

    return records


def exact_words(value: dict[str, Any]) -> set[str]:
    serialized = json.dumps(
        value,
        ensure_ascii=False,
        sort_keys=True,
    ).lower()

    return set(
        re.findall(
            r"[a-z0-9_]+",
            serialized,
        )
    )


def main() -> int:
    if len(sys.argv) != 4:
        fail("USAGE")

    capability_path = Path(sys.argv[1]).resolve()
    architecture_path = Path(sys.argv[2]).resolve()
    contracts_path = Path(sys.argv[3]).resolve()

    capability_map = load_json(capability_path)
    architecture = load_json(architecture_path)
    contracts = load_json(contracts_path)

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

    if (
        architecture.get("metadata", {}).get("status")
        != "immutable"
    ):
        fail("ARCHITECTURE_STATUS")

    if (
        contracts.get("kind")
        != "ConstitutionalContracts"
    ):
        fail("CONTRACT_INDEX_KIND")

    if (
        contracts.get("metadata", {}).get("id")
        != "constitutional-operational-contracts-v1"
    ):
        fail("CONTRACT_INDEX_ID")

    if capability_map.get("apiVersion") != (
        "capability.sandra.io/v1"
    ):
        fail("API_VERSION")

    if capability_map.get("kind") != (
        "CanonicalCapabilityMap"
    ):
        fail("KIND")

    metadata = capability_map.get("metadata")

    if not isinstance(metadata, dict):
        fail("METADATA")

    if metadata.get("id") != (
        "canonical-capability-map-v1"
    ):
        fail("IDENTIFIER")

    if metadata.get("status") != "immutable":
        fail("STATUS_NOT_IMMUTABLE")

    if metadata.get("scope") != (
        "technology-independent-governance"
    ):
        fail("SCOPE")

    spec = capability_map.get("spec")

    if not isinstance(spec, dict):
        fail("SPEC")

    if spec.get("architectureConstitution") != (
        "architecture-constitution-v1"
    ):
        fail("ARCHITECTURE_REFERENCE")

    if spec.get("constitutionalContracts") != (
        "constitutional-operational-contracts-v1"
    ):
        fail("CONTRACT_REFERENCE")

    principles = set(
        require_unique_strings(
            spec.get("principles"),
            "principles",
        )
    )

    if principles != REQUIRED_PRINCIPLES:
        fail("PRINCIPLE_SET")

    extension_rules = set(
        require_unique_strings(
            spec.get("extensionRules"),
            "extensionRules",
        )
    )

    if extension_rules != REQUIRED_EXTENSION_RULES:
        fail("EXTENSION_RULE_SET")

    core = require_records_by_id(
        spec.get("coreCapabilities"),
        "coreCapabilities",
    )

    families = require_records_by_id(
        spec.get("operationalFamilies"),
        "operationalFamilies",
    )

    if set(core) != EXPECTED_CORE:
        fail(
            "CORE_SET:"
            + ",".join(sorted(set(core)))
        )

    if set(families) != EXPECTED_FAMILIES:
        fail(
            "FAMILY_SET:"
            + ",".join(sorted(set(families)))
        )

    for identifier, record in core.items():
        require_string(
            record.get("purpose"),
            f"coreCapabilities.{identifier}.purpose",
        )

        owns = require_unique_strings(
            record.get("owns"),
            f"coreCapabilities.{identifier}.owns",
        )

        excludes = require_unique_strings(
            record.get("excludes"),
            f"coreCapabilities.{identifier}.excludes",
        )

        overlap = set(owns) & set(excludes)

        if overlap:
            fail(
                f"OWNS_EXCLUDES_OVERLAP:{identifier}:"
                + ",".join(sorted(overlap))
            )

        forbidden_present = sorted(
            exact_words(record)
            & FORBIDDEN_CORE_TERMS
        )

        if forbidden_present:
            fail(
                f"PRODUCT_TERM:{identifier}:"
                + ",".join(forbidden_present)
            )

    for identifier, record in families.items():
        require_string(
            record.get("purpose"),
            f"operationalFamilies.{identifier}.purpose",
        )

    derived_terms = spec.get("derivedTerms")

    if not isinstance(derived_terms, dict):
        fail("DERIVED_TERMS")

    expected_derived_terms = {
        "discovery": "observation",
        "inventory": "resource_graph plus persistence",
        "remediation": (
            "security_governance plus planning "
            "plus execution plus verification"
        ),
        "approval": "policy_decision plus notification",
        "health": "qualified observed status",
        "rollback": "execution recovery",
        "provider": (
            "forbidden canonical term; use adapter"
        ),
        "Habitat": (
            "governance boundary represented "
            "by the resource graph"
        ),
    }

    if derived_terms != expected_derived_terms:
        fail("DERIVED_TERM_SET")

    print("CANONICAL_CAPABILITY_MAP_VALIDATOR=PASS")
    print("CAPABILITY_MAP_CONTENT=PASS")
    print(f"CORE_CAPABILITY_COUNT={len(core)}")
    print(f"OPERATIONAL_FAMILY_COUNT={len(families)}")
    print("PRODUCT_TERMS_IN_CORE=NONE")
    print("PUBLICATION_STATUS=PUBLISHED")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
