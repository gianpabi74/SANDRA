"""Tests for deterministic canonical resource validation."""

from __future__ import annotations

import copy
import json
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
        knowledge_root = (
            Path(__file__).resolve().parents[3]
        )
        cls.example_root = (
            knowledge_root
            / "docs"
            / "specs"
            / "governance-model"
            / "examples"
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
