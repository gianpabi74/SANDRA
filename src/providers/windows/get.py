import json
import pathlib
import sys

from transport import execute_ps


PROVIDER_VERSION = "1.5.0"

MODULE_LOCALES = {
    "SMBShare": "en-US",
}

DEFAULT_LOCALE = "it-IT"


target_name, target_ip, profile_name, username, common_path, role_path = sys.argv[1:7]
password = sys.stdin.read()

if not password:
    raise SystemExit("PASSWORD_EMPTY")


def parse_profile(path: str) -> dict[str, list[str]]:
    result = {
        "features": [],
        "modules": [],
        "services": [],
    }

    section = None

    mapping = {
        "## Windows Features": "features",
        "## PowerShell Modules": "modules",
        "## Windows Services": "services",
    }

    for raw_line in pathlib.Path(path).read_text(
        encoding="utf-8"
    ).splitlines():
        line = raw_line.strip()

        if line in mapping:
            section = mapping[line]
        elif line.startswith("## "):
            section = None
        elif section and line.startswith("- "):
            value = line[2:].strip()

            if value not in result[section]:
                result[section].append(value)

    return result


def merge_profiles(paths: tuple[str, str]) -> dict[str, list[str]]:
    desired = {
        "features": [],
        "modules": [],
        "services": [],
    }

    for profile_path in paths:
        parsed = parse_profile(profile_path)

        for key in desired:
            for value in parsed[key]:
                if value not in desired[key]:
                    desired[key].append(value)

    return desired


def ps_array(values: list[str]) -> str:
    return "@(" + ",".join(json.dumps(value) for value in values) + ")"


def inspect_modules(locale: str, module_names: list[str]) -> list[dict]:
    if not module_names:
        return []

    script = f"""
$ErrorActionPreference = "Stop"
$desiredModules = {ps_array(module_names)}

$result = @(
    foreach ($name in $desiredModules) {{
        $available = Get-Module -ListAvailable -Name $name |
            Select-Object -First 1

        $present = $null -ne $available
        $importable = $false
        $errorText = $null
        $version = $null
        $path = $null

        if ($present) {{
            $version = $available.Version.ToString()
            $path = $available.Path

            try {{
                Import-Module -Name $name -Force -ErrorAction Stop
                $importable = $true
            }}
            catch {{
                $errorText = $_.Exception.Message
            }}
        }}

        [pscustomobject]@{{
            Name = $name
            Present = $present
            Importable = $importable
            Error = $errorText
            Version = $version
            Path = $path
            Locale = (Get-UICulture).Name
        }}
    }}
)

[ordered]@{{
    ComputerName = $env:COMPUTERNAME
    Culture = (Get-Culture).Name
    UICulture = (Get-UICulture).Name
    Modules = $result
}} | ConvertTo-Json -Depth 8 -Compress
"""

    document = execute_ps(
        target_ip,
        username,
        password,
        locale,
        script,
    )

    if document["ComputerName"].upper() != target_name.upper():
        raise RuntimeError(
            "COMPUTER_NAME_MISMATCH:"
            + document["ComputerName"]
            + ":"
            + target_name
        )

    return document["Modules"]


desired = merge_profiles((common_path, role_path))

modules_by_locale: dict[str, list[str]] = {}

for module_name in desired["modules"]:
    module_locale = MODULE_LOCALES.get(module_name, DEFAULT_LOCALE)
    modules_by_locale.setdefault(module_locale, []).append(module_name)


base_script = f"""
$ErrorActionPreference = "Stop"
$desiredServices = {ps_array(desired["services"])}

$os = Get-CimInstance -ClassName Win32_OperatingSystem
$computer = Get-CimInstance -ClassName Win32_ComputerSystem

$installedFeatures = @(
    Get-WindowsFeature |
    Where-Object {{ $_.Installed }} |
    Select-Object -ExpandProperty Name
)

$services = @(
    foreach ($name in $desiredServices) {{
        $escapedName = $name.Replace("'", "''")

        $service = Get-CimInstance `
            -ClassName Win32_Service `
            -Filter ("Name='" + $escapedName + "'") `
            -ErrorAction SilentlyContinue

        if ($null -eq $service) {{
            [pscustomobject]@{{
                Name = $name
                Present = $false
                State = $null
                StartMode = $null
            }}
        }}
        else {{
            [pscustomobject]@{{
                Name = $service.Name
                Present = $true
                State = $service.State
                StartMode = $service.StartMode
            }}
        }}
    }}
)

[ordered]@{{
    ComputerName = $env:COMPUTERNAME
    Identity = [Security.Principal.WindowsIdentity]::GetCurrent().Name
    Culture = (Get-Culture).Name
    UICulture = (Get-UICulture).Name
    SystemLocale = (Get-WinSystemLocale).Name
    OSCaption = $os.Caption
    OSVersion = $os.Version
    BuildNumber = $os.BuildNumber
    Domain = $computer.Domain
    DomainRole = $computer.DomainRole
    PartOfDomain = $computer.PartOfDomain
    PowerShellVersion = $PSVersionTable.PSVersion.ToString()
    InstalledFeatures = $installedFeatures
    Services = $services
}} | ConvertTo-Json -Depth 8 -Compress
"""


try:
    current = execute_ps(
        target_ip,
        username,
        password,
        DEFAULT_LOCALE,
        base_script,
    )

    if current["ComputerName"].upper() != target_name.upper():
        raise RuntimeError(
            "COMPUTER_NAME_MISMATCH:"
            + current["ComputerName"]
            + ":"
            + target_name
        )

    module_states = []

    for locale_name in sorted(modules_by_locale):
        module_states.extend(
            inspect_modules(
                locale_name,
                modules_by_locale[locale_name],
            )
        )

    module_order = {
        name: index
        for index, name in enumerate(desired["modules"])
    }

    module_states.sort(
        key=lambda item: module_order[item["Name"]]
    )

    current["Modules"] = module_states
    current["ModuleLocalePolicy"] = {
        "Default": DEFAULT_LOCALE,
        "Overrides": MODULE_LOCALES,
    }

    print(
        json.dumps(
            {
                "Provider": "Windows",
                "ProviderVersion": PROVIDER_VERSION,
                "Operation": "Get",
                "Target": target_name,
                "TargetIP": target_ip,
                "Profile": profile_name,
                "CurrentState": current,
            },
            indent=2,
            ensure_ascii=False,
        )
    )

except Exception as exc:
    message = str(exc).replace(password, "<REDACTED>")

    print(
        json.dumps(
            {
                "Provider": "Windows",
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
