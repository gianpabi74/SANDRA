import json
import pathlib
import sys

from transport import execute_ssh


PROVIDER_VERSION = "1.0.0"


if len(sys.argv) != 5:
    raise SystemExit(
        "USAGE: get.py "
        "<target-name> <target-ip> <profile> <username>"
    )


target_name, target_ip, profile_name, username = sys.argv[1:5]
password = sys.stdin.read()

if not password:
    raise SystemExit("PASSWORD_EMPTY")


remote_script = r'''
import json
import pathlib
import platform
import shutil
import socket
import subprocess


def run(command):
    result = subprocess.run(
        command,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        timeout=60,
        check=False,
    )

    return {
        "ReturnCode": result.returncode,
        "Stdout": result.stdout.strip(),
        "Stderr": result.stderr.strip(),
    }


def read_text(path):
    try:
        return pathlib.Path(path).read_text(
            encoding="utf-8",
            errors="replace",
        ).strip()
    except Exception:
        return ""


def os_release():
    result = {}

    for line in read_text("/etc/os-release").splitlines():
        if "=" not in line:
            continue

        key, value = line.split("=", 1)
        result[key] = value.strip().strip('"')

    return result


def package_manager():
    for name in (
        "apt-get",
        "dnf",
        "yum",
        "zypper",
        "pacman",
        "apk",
    ):
        if shutil.which(name):
            return name

    return None


def virtualization():
    if shutil.which("systemd-detect-virt"):
        result = run(["systemd-detect-virt"])

        if result["Stdout"]:
            return result["Stdout"]

    value = read_text("/run/systemd/container")

    if value:
        return value

    return "unknown"


def failed_units():
    result = run(
        [
            "systemctl",
            "list-units",
            "--failed",
            "--all",
            "--output=json",
            "--no-pager",
        ]
    )

    if result["ReturnCode"] != 0:
        return {
            "Supported": False,
            "Error": result["Stderr"],
            "Units": [],
        }

    try:
        records = json.loads(result["Stdout"])
    except Exception as exc:
        return {
            "Supported": False,
            "Error": (
                "JSON_DECODE_ERROR:"
                + type(exc).__name__
            ),
            "Units": [],
        }

    units = []

    for record in records:
        if not isinstance(record, dict):
            continue

        unit_name = record.get("unit")

        if not unit_name:
            continue

        show_result = run(
            [
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
                "--property=Result",
                "--property=ExecMainStatus",
                "--property=FragmentPath",
            ]
        )

        properties = {}

        for line in show_result["Stdout"].splitlines():
            if "=" not in line:
                continue

            key, value = line.split("=", 1)
            properties[key] = value

        units.append(
            {
                "Name": unit_name,
                "Properties": properties,
            }
        )

    return {
        "Supported": True,
        "Error": None,
        "Units": units,
    }


release = os_release()
system_state = run(["systemctl", "is-system-running"])

document = {
    "ComputerName": socket.gethostname(),
    "FQDN": socket.getfqdn(),
    "MachineId": read_text("/etc/machine-id"),
    "OS": {
        "ID": release.get("ID"),
        "Name": release.get("NAME"),
        "PrettyName": release.get("PRETTY_NAME"),
        "VersionID": release.get("VERSION_ID"),
    },
    "Kernel": platform.release(),
    "Architecture": platform.machine(),
    "PID1": read_text("/proc/1/comm"),
    "Virtualization": virtualization(),
    "PackageManager": package_manager(),
    "Systemd": {
        "Present": shutil.which("systemctl") is not None,
        "SystemState": system_state["Stdout"],
        "SystemStateRC": system_state["ReturnCode"],
        "Failed": failed_units(),
    },
    "Fstab": read_text("/etc/fstab"),
    "RootFilesystem": run(
        [
            "findmnt",
            "-n",
            "-o",
            "SOURCE,FSTYPE,OPTIONS",
            "/",
        ]
    )["Stdout"],
}

print(
    json.dumps(
        document,
        ensure_ascii=False,
        separators=(",", ":"),
    )
)
'''


try:
    output = execute_ssh(
        target_ip,
        username,
        password,
        ["python3", "-"],
        stdin_text=remote_script,
        command_timeout=180,
    )

    current = json.loads(output.strip())

    actual_name = str(
        current.get("ComputerName", "")
    ).upper()

    if actual_name != target_name.upper():
        raise RuntimeError(
            "COMPUTER_NAME_MISMATCH:"
            + actual_name
            + ":"
            + target_name.upper()
        )

    result = {
        "Provider": "Linux",
        "ProviderVersion": PROVIDER_VERSION,
        "Operation": "Get",
        "Target": target_name,
        "TargetIP": target_ip,
        "Profile": profile_name,
        "CurrentState": current,
    }

    print(
        json.dumps(
            result,
            indent=2,
            ensure_ascii=False,
        )
    )

except Exception as exc:
    message = str(exc).replace(
        password,
        "<REDACTED>",
    )

    print(
        json.dumps(
            {
                "Provider": "Linux",
                "ProviderVersion": PROVIDER_VERSION,
                "Operation": "Get",
                "Target": target_name,
                "TargetIP": target_ip,
                "Profile": profile_name,
                "ErrorType": type(exc).__name__,
                "Error": message,
            },
            indent=2,
            ensure_ascii=False,
        )
    )

    raise SystemExit(2)
