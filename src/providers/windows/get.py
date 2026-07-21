import json
import pathlib
import sys
from pypsrp.client import Client

target_name, target_ip, profile_name, username, common_path, role_path = sys.argv[1:7]
password = sys.stdin.read()
if not password:
    raise SystemExit("PASSWORD_EMPTY")

def parse_profile(path):
    result = {"features": [], "modules": [], "services": []}
    section = None
    mapping = {
        "## Windows Features": "features",
        "## PowerShell Modules": "modules",
        "## Windows Services": "services",
    }
    for raw in pathlib.Path(path).read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if line in mapping:
            section = mapping[line]
        elif line.startswith("## "):
            section = None
        elif section and line.startswith("- "):
            value = line[2:].strip()
            if value not in result[section]:
                result[section].append(value)
    return result

desired = {"features": [], "modules": [], "services": []}
for p in (common_path, role_path):
    parsed = parse_profile(p)
    for key in desired:
        for value in parsed[key]:
            if value not in desired[key]:
                desired[key].append(value)

def ps_array(values):
    return "@(" + ",".join(json.dumps(v) for v in values) + ")"

ps = f"""
$ErrorActionPreference = 'Stop'
$desiredModules = {ps_array(desired['modules'])}
$desiredServices = {ps_array(desired['services'])}
$os = Get-CimInstance Win32_OperatingSystem
$computer = Get-CimInstance Win32_ComputerSystem
$installedFeatures = @(Get-WindowsFeature | Where-Object Installed | Select-Object -ExpandProperty Name)
$availableModules = @(Get-Module -ListAvailable | Select-Object -ExpandProperty Name -Unique)
$modules = @(
  foreach ($name in $desiredModules) {{
    $present = $availableModules -contains $name
    $importable = $false
    $errorText = $null
    if ($present) {{
      try {{
        Import-Module -Name $name -Force -ErrorAction Stop
        $importable = $true
      }} catch {{
        $errorText = $_.Exception.Message
      }}
    }}
    [pscustomobject]@{{Name=$name;Present=$present;Importable=$importable;Error=$errorText}}
  }}
)
$services = @(
  foreach ($name in $desiredServices) {{
    $svc = Get-CimInstance Win32_Service -Filter ("Name='" + $name.Replace("'", "''") + "'") -ErrorAction SilentlyContinue
    if ($null -eq $svc) {{
      [pscustomobject]@{{Name=$name;Present=$false;State=$null;StartMode=$null}}
    }} else {{
      [pscustomobject]@{{Name=$svc.Name;Present=$true;State=$svc.State;StartMode=$svc.StartMode}}
    }}
  }}
)
[ordered]@{{
  ComputerName=$env:COMPUTERNAME
  Identity=[Security.Principal.WindowsIdentity]::GetCurrent().Name
  OSCaption=$os.Caption
  OSVersion=$os.Version
  BuildNumber=$os.BuildNumber
  Domain=$computer.Domain
  DomainRole=$computer.DomainRole
  PartOfDomain=$computer.PartOfDomain
  PowerShellVersion=$PSVersionTable.PSVersion.ToString()
  InstalledFeatures=$installedFeatures
  Modules=$modules
  Services=$services
}} | ConvertTo-Json -Depth 8 -Compress
"""

try:
    with Client(
        target_ip,
        username=username,
        password=password,
        ssl=False,
        port=5985,
        auth="ntlm",
        encryption="always",
        no_proxy=True,
        locale="it-IT",
        data_locale="it-IT",
        connection_timeout=10,
        read_timeout=60,
    ) as client:
        output, streams, had_errors = client.execute_ps(ps)
    if had_errors:
        raise RuntimeError("; ".join(str(x) for x in streams.error) or "REMOTE_POWERSHELL_ERROR")
    current = json.loads(output.strip())
    if current["ComputerName"].upper() != target_name.upper():
        raise RuntimeError(f"COMPUTER_NAME_MISMATCH:{current['ComputerName']}:{target_name}")
    print(json.dumps({
        "Provider": "Windows",
        "ProviderVersion": "1.1.0",
        "Operation": "Get",
        "Target": target_name,
        "TargetIP": target_ip,
        "Profile": profile_name,
        "CurrentState": current,
    }, indent=2, ensure_ascii=False))
except Exception as exc:
    message = str(exc).replace(password, "<REDACTED>")
    print(json.dumps({
        "Provider": "Windows",
        "ProviderVersion": "1.1.0",
        "Operation": "Get",
        "Target": target_name,
        "TargetIP": target_ip,
        "Profile": profile_name,
        "ErrorType": type(exc).__name__,
        "Error": message,
    }, indent=2, ensure_ascii=False))
    raise SystemExit(2)