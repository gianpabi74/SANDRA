"""Command-line interface for canonical resource validation."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Sequence

from .errors import GovernanceError
from .validation import load_resource


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="governance-resource",
        description=(
            "Validate canonical governance resource documents."
        ),
    )

    parser.add_argument(
        "paths",
        nargs="+",
        type=Path,
        help="JSON resource documents to validate",
    )

    return parser


def main(argv: Sequence[str] | None = None) -> int:
    parser = build_parser()
    arguments = parser.parse_args(argv)

    results: list[dict[str, str]] = []
    failed = False

    for path in arguments.paths:
        try:
            resource = load_resource(path)
        except GovernanceError as exc:
            failed = True
            results.append(
                {
                    "path": str(path),
                    "status": "FAIL",
                    "error": str(exc),
                }
            )
        else:
            results.append(
                {
                    "path": str(path),
                    "status": "PASS",
                    "apiVersion": resource.api_version,
                    "kind": resource.kind.value,
                    "id": resource.metadata.identifier,
                }
            )

    print(
        json.dumps(
            results,
            indent=2,
            ensure_ascii=False,
        )
    )

    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
