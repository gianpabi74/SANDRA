# Governance Resource CLI

Inbound adapter for validating canonical governance resource documents.

The adapter owns:

- command-line argument parsing;
- terminal exit codes;
- JSON rendering for CLI consumers.

The canonical domain owns:

- resource types;
- domain errors;
- validation invariants;
- resource loading and normalization.

Run with both canonical roots available:

    PYTHONPATH=src/sandra/domain:src/sandra/adapters/inbound \
    python3 -m governance_resource_cli RESOURCE.json
