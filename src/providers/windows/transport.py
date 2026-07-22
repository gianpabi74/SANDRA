import json

from pypsrp.client import Client


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
