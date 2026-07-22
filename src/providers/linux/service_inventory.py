#!/usr/bin/env python3

import argparse
import json
import pathlib
import subprocess
import sys
from datetime import datetime, timezone

from transport import execute_ssh


PROVIDER_VERSION = "1.1.1"


REMOTE_SCRIPT = r'''
import json
import socket
import subprocess
from datetime import datetime, timezone


def run(arguments):
    completed = subprocess.run(
        arguments,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
        timeout=120,
    )

    return {
        "ReturnCode": completed.returncode,
        "Stdout": completed.stdout,
        "Stderr": completed.stderr,
    }


def parse_properties(text):
    properties = {}

    for line in text.splitlines():
        if "=" not in line:
            continue

        key, value = line.split("=", 1)
        properties[key] = value

    return properties


def classify(name, fragment_path):
    application_prefixes = (
        "/etc/systemd/system/",
        "/usr/local/lib/systemd/system/",
        "/usr/local/etc/systemd/system/",
        "/opt/",
    )

    infrastructure_names = {
        "cron.service",
        "crond.service",
        "dbus.service",
        "networking.service",
        "NetworkManager.service",
        "systemd-networkd.service",
        "systemd-resolved.service",
        "ssh.service",
        "sshd.service",
        "rsyslog.service",
        "systemd-timesyncd.service",
        "chrony.service",
        "chronyd.service",
        "qemu-guest-agent.service",
    }

    if fragment_path.startswith(application_prefixes):
        return "application"

    if name in infrastructure_names:
        return "infrastructure"

    return "operating_system"


def candidate_reason(
    name,
    load_state,
    unit_file_state,
    fragment_path,
    classification,
):
    if classification != "application":
        return False, "CLASSIFICATION_NOT_APPLICATION"

    if load_state != "loaded":
        return False, "UNIT_NOT_LOADED"

    if not fragment_path:
        return False, "FRAGMENT_PATH_EMPTY"

    if fragment_path.startswith("/run/"):
        return False, "RUNTIME_GENERATED_UNIT"

    if "@" in name:
        return False, "TEMPLATE_OR_INSTANCE_UNIT"

    if unit_file_state not in {
        "enabled",
        "enabled-runtime",
        "disabled",
        "indirect",
    }:
        return False, "UNIT_FILE_STATE_NOT_GOVERNABLE"

    return True, "APPLICATION_SERVICE_WITH_PERSISTENT_UNIT"


list_units = run([
    "systemctl",
    "list-units",
    "--type=service",
    "--all",
    "--no-legend",
    "--no-pager",
    "--plain",
])

list_unit_files = run([
    "systemctl",
    "list-unit-files",
    "--type=service",
    "--no-legend",
    "--no-pager",
])

failed_units = run([
    "systemctl",
    "list-units",
    "--type=service",
    "--state=failed",
    "--no-legend",
    "--no-pager",
    "--plain",
])

if list_units["ReturnCode"] != 0:
    raise SystemExit(
        "SYSTEMCTL_LIST_UNITS_FAILED:"
        + list_units["Stderr"].strip()
    )

if list_unit_files["ReturnCode"] != 0:
    raise SystemExit(
        "SYSTEMCTL_LIST_UNIT_FILES_FAILED:"
        + list_unit_files["Stderr"].strip()
    )

unit_file_states = {}

for line in list_unit_files["Stdout"].splitlines():
    fields = line.split()

    if len(fields) >= 2 and fields[0].endswith(".service"):
        unit_file_states[fields[0]] = fields[1]

unit_names = set()

for line in list_units["Stdout"].splitlines():
    fields = line.split()

    if fields and fields[0].endswith(".service"):
        unit_names.add(fields[0])

units = []

for unit_name in sorted(unit_names):
    show = run([
        "systemctl",
        "show",
        unit_name,
        "--no-pager",
        "--property=Id",
        "--property=Description",
        "--property=LoadState",
        "--property=ActiveState",
        "--property=SubState",
        "--property=UnitFileState",
        "--property=FragmentPath",
    ])

    if show["ReturnCode"] != 0:
        units.append({
            "Name": unit_name,
            "CollectionError": show["Stderr"].strip(),
            "Candidate": False,
            "CandidateReason": "COLLECTION_ERROR",
        })
        continue

    properties = parse_properties(show["Stdout"])

    if properties.get("Id") != unit_name:
        units.append({
            "Name": unit_name,
            "CollectionError": "SYSTEMD_ID_MISMATCH",
            "Candidate": False,
            "CandidateReason": "COLLECTION_ERROR",
        })
        continue

    fragment_path = properties.get("FragmentPath", "")
    load_state = properties.get("LoadState", "")
    unit_file_state = (
        properties.get("UnitFileState")
        or unit_file_states.get(unit_name, "")
    )

    classification = classify(
        unit_name,
        fragment_path,
    )

    candidate, reason = candidate_reason(
        unit_name,
        load_state,
        unit_file_state,
        fragment_path,
        classification,
    )

    units.append({
        "Name": unit_name,
        "Description": properties.get("Description", ""),
        "LoadState": load_state,
        "ActiveState": properties.get("ActiveState", ""),
        "SubState": properties.get("SubState", ""),
        "UnitFileState": unit_file_state,
        "FragmentPath": fragment_path,
        "Classification": classification,
        "Candidate": candidate,
        "CandidateReason": reason,
    })

failed_names = []

for line in failed_units["Stdout"].splitlines():
    fields = line.split()

    if fields and fields[0].endswith(".service"):
        failed_names.append(fields[0])

document = {
    "SchemaVersion": 1,
    "Provider": "Linux",
    "ProviderVersion": "1.1.1",
    "Operation": "ServiceInventory",
    "Mode": "remote_read_only_audit",
    "CollectedUTC": datetime.now(timezone.utc).isoformat(),
    "Host": {
        "Hostname": socket.gethostname(),
    },
    "CollectionContract": {
        "ReadOnly": True,
        "ModificationCommandsInvoked": [],
        "Properties": [
            "Name",
            "Description",
            "LoadState",
            "ActiveState",
            "SubState",
            "UnitFileState",
            "FragmentPath",
        ],
    },
    "Units": units,
    "FailedUnits": sorted(set(failed_names)),
    "Statistics": {
        "UnitCount": len(units),
        "FailedUnitCount": len(set(failed_names)),
        "ApplicationCount": sum(
            unit.get("Classification") == "application"
            for unit in units
        ),
        "InfrastructureCount": sum(
            unit.get("Classification") == "infrastructure"
            for unit in units
        ),
        "OperatingSystemCount": sum(
            unit.get("Classification") == "operating_system"
            for unit in units
        ),
        "CandidateCount": sum(
            unit.get("Candidate") is True
            for unit in units
        ),
        "CollectionErrorCount": sum(
            bool(unit.get("CollectionError"))
            for unit in units
        ),
    },
}

print(
    json.dumps(
        document,
        indent=2,
        ensure_ascii=False,
    )
)
'''


def collect_host(arguments):
    output = execute_ssh(
        arguments.target_ip,
        arguments.username,
        ["python3", "-"],
        stdin_text=REMOTE_SCRIPT,
        command_timeout=240,
    )

    document = json.loads(output)

    actual_hostname = str(
        document.get("Host", {}).get("Hostname", "")
    ).upper()

    if actual_hostname != arguments.target_name.upper():
        raise RuntimeError(
            "COMPUTER_NAME_MISMATCH:"
            + actual_hostname
            + ":"
            + arguments.target_name.upper()
        )

    document["Target"] = arguments.target_name
    document["TargetIP"] = arguments.target_ip

    pathlib.Path(arguments.output).write_text(
        json.dumps(
            document,
            indent=2,
            ensure_ascii=False,
        ) + "\n",
        encoding="utf-8",
    )


def summarize(arguments):
    inventory_root = pathlib.Path(arguments.inventory_root)

    hosts = []

    for path in sorted(inventory_root.glob("*.json")):
        document = json.loads(
            path.read_text(encoding="utf-8")
        )

        statistics = document["Statistics"]

        candidates = [
            {
                "Name": unit["Name"],
                "Description": unit.get("Description", ""),
                "ActiveState": unit.get("ActiveState", ""),
                "SubState": unit.get("SubState", ""),
                "UnitFileState": unit.get("UnitFileState", ""),
                "FragmentPath": unit.get("FragmentPath", ""),
                "CandidateReason": unit.get(
                    "CandidateReason",
                    "",
                ),
            }
            for unit in document["Units"]
            if unit.get("Candidate") is True
        ]

        hosts.append({
            "Target": document["Target"],
            "TargetIP": document["TargetIP"],
            "Hostname": document["Host"]["Hostname"],
            "Statistics": statistics,
            "FailedUnits": document["FailedUnits"],
            "Candidates": candidates,
        })

    totals = {
        "HostCount": len(hosts),
        "UnitCount": sum(
            host["Statistics"]["UnitCount"]
            for host in hosts
        ),
        "FailedUnitCount": sum(
            host["Statistics"]["FailedUnitCount"]
            for host in hosts
        ),
        "CandidateCount": sum(
            host["Statistics"]["CandidateCount"]
            for host in hosts
        ),
        "CollectionErrorCount": sum(
            host["Statistics"]["CollectionErrorCount"]
            for host in hosts
        ),
    }

    summary = {
        "SchemaVersion": 1,
        "Provider": "Linux",
        "ProviderVersion": PROVIDER_VERSION,
        "Operation": "ServiceInventorySummary",
        "RunBook": arguments.runbook,
        "RunID": arguments.run_id,
        "Status": (
            "pass"
            if totals["CollectionErrorCount"] == 0
            else "fail"
        ),
        "ReadOnlyAudit": True,
        "ModificationCommandsInvoked": [],
        "GeneratedUTC": datetime.now(
            timezone.utc
        ).isoformat(),
        "Totals": totals,
        "Hosts": hosts,
    }

    pathlib.Path(arguments.output_json).write_text(
        json.dumps(
            summary,
            indent=2,
            ensure_ascii=False,
        ) + "\n",
        encoding="utf-8",
    )

    lines = [
        "TARGET|IP|UNITS|FAILED|CANDIDATES|COLLECTION_ERRORS"
    ]

    for host in hosts:
        statistics = host["Statistics"]

        lines.append(
            "{target}|{ip}|{units}|{failed}|"
            "{candidates}|{errors}".format(
                target=host["Target"],
                ip=host["TargetIP"],
                units=statistics["UnitCount"],
                failed=statistics["FailedUnitCount"],
                candidates=statistics["CandidateCount"],
                errors=statistics["CollectionErrorCount"],
            )
        )

    pathlib.Path(arguments.output_text).write_text(
        "\n".join(lines) + "\n",
        encoding="utf-8",
    )


def build_parser():
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(
        dest="operation",
        required=True,
    )

    host_parser = subparsers.add_parser("host")
    host_parser.add_argument("target_name")
    host_parser.add_argument("target_ip")
    host_parser.add_argument("username")
    host_parser.add_argument("output")
    host_parser.set_defaults(handler=collect_host)

    summary_parser = subparsers.add_parser("summary")
    summary_parser.add_argument("inventory_root")
    summary_parser.add_argument("output_json")
    summary_parser.add_argument("output_text")
    summary_parser.add_argument("runbook")
    summary_parser.add_argument("run_id")
    summary_parser.set_defaults(handler=summarize)

    return parser


def main():
    parser = build_parser()
    arguments = parser.parse_args()
    arguments.handler(arguments)


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print(
            json.dumps(
                {
                    "Provider": "Linux",
                    "ProviderVersion": PROVIDER_VERSION,
                    "Operation": "ServiceInventory",
                    "ErrorType": type(exc).__name__,
                    "Error": str(exc),
                },
                indent=2,
                ensure_ascii=False,
            ),
            file=sys.stderr,
        )
        raise SystemExit(2)
