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
