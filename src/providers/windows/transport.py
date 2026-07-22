import base64
import json
import re

from pypsrp.client import Client


_SAFE_DSC_IDENTIFIER = re.compile(r"^[A-Za-z0-9_.-]+$")
_DSC_METHODS = {"Test", "Set"}


def execute_ps(
    host: str,
    username: str,
    password: str,
    locale: str,
    script: str,
    *,
    connection_timeout: int = 10,
    read_timeout: int = 90,
) -> dict:
    if not host:
        raise ValueError("HOST_EMPTY")

    if not username:
        raise ValueError("USERNAME_EMPTY")

    if not password:
        raise ValueError("PASSWORD_EMPTY")

    if not locale:
        raise ValueError("LOCALE_EMPTY")

    if not script:
        raise ValueError("SCRIPT_EMPTY")

    with Client(
        host,
        username=username,
        password=password,
        ssl=False,
        port=5985,
        auth="ntlm",
        encryption="always",
        no_proxy=True,
        locale=locale,
        data_locale=locale,
        connection_timeout=connection_timeout,
        read_timeout=read_timeout,
    ) as client:
        output, streams, had_errors = client.execute_ps(script)

    if had_errors:
        errors = "; ".join(
            str(item)
            for item in streams.error
        )

        raise RuntimeError(
            errors or "REMOTE_POWERSHELL_ERROR"
        )

    return json.loads(output.strip())


def invoke_dsc_resource(
    host: str,
    expected_target: str,
    username: str,
    password: str,
    locale: str,
    resource: str,
    module: str,
    method: str,
    properties: dict,
    *,
    connection_timeout: int = 10,
    read_timeout: int = 120,
) -> dict:
    if not expected_target:
        raise ValueError("EXPECTED_TARGET_EMPTY")

    if (
        not isinstance(resource, str)
        or not _SAFE_DSC_IDENTIFIER.fullmatch(resource)
    ):
        raise ValueError("DSC_RESOURCE_INVALID")

    if (
        not isinstance(module, str)
        or not _SAFE_DSC_IDENTIFIER.fullmatch(module)
    ):
        raise ValueError("DSC_MODULE_INVALID")

    if method not in _DSC_METHODS:
        raise ValueError("DSC_METHOD_INVALID")

    if not isinstance(properties, dict) or not properties:
        raise ValueError("DSC_PROPERTIES_INVALID")

    properties_json = json.dumps(
        properties,
        ensure_ascii=False,
        separators=(",", ":"),
    )

    resource_b64 = base64.b64encode(
        resource.encode("utf-8")
    ).decode("ascii")

    module_b64 = base64.b64encode(
        module.encode("utf-8")
    ).decode("ascii")

    method_b64 = base64.b64encode(
        method.encode("utf-8")
    ).decode("ascii")

    properties_b64 = base64.b64encode(
        properties_json.encode("utf-8")
    ).decode("ascii")

    script = f'''
$ErrorActionPreference = "Stop"

function ConvertFrom-SandraBase64 {{
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    [Text.Encoding]::UTF8.GetString(
        [Convert]::FromBase64String($Value)
    )
}}

$resourceName = ConvertFrom-SandraBase64 "{resource_b64}"
$moduleName = ConvertFrom-SandraBase64 "{module_b64}"
$methodName = ConvertFrom-SandraBase64 "{method_b64}"

$propertiesJson = ConvertFrom-SandraBase64 "{properties_b64}"
$propertiesObject = $propertiesJson | ConvertFrom-Json

$properties = @{{}}

foreach ($property in $propertiesObject.PSObject.Properties) {{
    $properties[$property.Name] = $property.Value
}}

$result = Invoke-DscResource `
    -Name $resourceName `
    -ModuleName $moduleName `
    -Method $methodName `
    -Property $properties `
    -ErrorAction Stop

$normalizedResult = $null

if ($methodName -eq "Test") {{
    $normalizedResult = [ordered]@{{
        InDesiredState = [bool]$result.InDesiredState
    }}
}}
elseif ($methodName -eq "Set") {{
    $normalizedResult = [ordered]@{{
        ReturnedObject = ($null -ne $result)
    }}
}}

[ordered]@{{
    ComputerName = $env:COMPUTERNAME
    Resource = $resourceName
    Module = $moduleName
    Method = $methodName
    Result = $normalizedResult
}} | ConvertTo-Json -Depth 8 -Compress
'''

    document = execute_ps(
        host,
        username,
        password,
        locale,
        script,
        connection_timeout=connection_timeout,
        read_timeout=read_timeout,
    )

    actual_target = str(
        document.get("ComputerName", "")
    ).upper()

    if actual_target != expected_target.upper():
        raise RuntimeError(
            "COMPUTER_NAME_MISMATCH:"
            + actual_target
            + ":"
            + expected_target.upper()
        )

    if document.get("Resource") != resource:
        raise RuntimeError("DSC_RESOURCE_RESULT_MISMATCH")

    if document.get("Module") != module:
        raise RuntimeError("DSC_MODULE_RESULT_MISMATCH")

    if document.get("Method") != method:
        raise RuntimeError("DSC_METHOD_RESULT_MISMATCH")

    if not isinstance(document.get("Result"), dict):
        raise RuntimeError("DSC_RESULT_INVALID")

    return document
