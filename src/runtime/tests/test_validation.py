"""Tests for deterministic canonical resource validation."""

from __future__ import annotations

import copy
import json
import os
import unittest
from pathlib import Path

from governance.errors import (
    ResourceValidationError,
    UnsupportedResourceError,
)
from governance.types import ResourceKind
from governance.validation import (
    load_resource,
    validate_document,
)


class ResourceValidationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        configured_root = os.environ.get(
            "SANDRA_TEST_EXAMPLE_ROOT"
        )

        if not configured_root:
            raise RuntimeError(
                "SANDRA_TEST_EXAMPLE_ROOT is required"
            )

        cls.example_root = Path(
            configured_root
        ).resolve()

        if not cls.example_root.is_dir():
            raise RuntimeError(
                "SANDRA_TEST_EXAMPLE_ROOT is not a directory: "
                f"{cls.example_root}"
            )

    def load_example(
        self,
        filename: str,
    ) -> dict:
        return json.loads(
            (
                self.example_root
                / filename
            ).read_text(encoding="utf-8")
        )

    def test_managed_object_is_valid(self) -> None:
        resource = load_resource(
            self.example_root
            / "managed-object.example.json"
        )

        self.assertEqual(
            resource.kind,
            ResourceKind.MANAGED_OBJECT,
        )
        self.assertEqual(
            resource.metadata.identifier,
            "obj_01k0example000001",
        )

    def test_all_examples_are_valid(self) -> None:
        for path in sorted(
            self.example_root.glob("*.json")
        ):
            with self.subTest(path=path.name):
                load_resource(path)

    def test_unknown_api_version_is_rejected(self) -> None:
        document = self.load_example(
            "managed-object.example.json"
        )
        document["apiVersion"] = "unknown/v1"

        with self.assertRaises(
            UnsupportedResourceError
        ):
            validate_document(document)

    def test_unknown_kind_is_rejected(self) -> None:
        document = self.load_example(
            "managed-object.example.json"
        )
        document["kind"] = "UnknownResource"

        with self.assertRaises(
            UnsupportedResourceError
        ):
            validate_document(document)

    def test_unexpected_root_field_is_rejected(
        self,
    ) -> None:
        document = self.load_example(
            "managed-object.example.json"
        )
        document["unexpected"] = True

        with self.assertRaises(
            ResourceValidationError
        ):
            validate_document(document)

    def test_invalid_identifier_is_rejected(self) -> None:
        document = self.load_example(
            "managed-object.example.json"
        )
        document["metadata"]["id"] = "VM120"

        with self.assertRaises(
            ResourceValidationError
        ):
            validate_document(document)

    def test_input_document_is_not_mutated(self) -> None:
        document = self.load_example(
            "managed-object.example.json"
        )
        original = copy.deepcopy(document)

        validate_document(document)

        self.assertEqual(document, original)


if __name__ == "__main__":
    unittest.main()
