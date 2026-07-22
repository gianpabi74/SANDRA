import pathlib
import shutil
import subprocess


DEFAULT_IDENTITY_FILE = pathlib.Path(
    "/opt/sandra/secrets/ssh/id_ed25519"
)

DEFAULT_KNOWN_HOSTS_FILE = pathlib.Path(
    "/opt/sandra/secrets/ssh/known_hosts"
)


def execute_ssh(
    host: str,
    username: str,
    command: list[str],
    *,
    stdin_text: str = "",
    identity_file: pathlib.Path = DEFAULT_IDENTITY_FILE,
    known_hosts_file: pathlib.Path = DEFAULT_KNOWN_HOSTS_FILE,
    connect_timeout: int = 10,
    command_timeout: int = 120,
) -> str:
    if not host:
        raise ValueError("HOST_EMPTY")

    if not username:
        raise ValueError("USERNAME_EMPTY")

    if not isinstance(command, list) or not command:
        raise ValueError("COMMAND_INVALID")

    if not all(
        isinstance(item, str) and item
        for item in command
    ):
        raise ValueError("COMMAND_ARGUMENT_INVALID")

    if not identity_file.is_file():
        raise RuntimeError("SSH_IDENTITY_FILE_NOT_FOUND")

    if not known_hosts_file.is_file():
        raise RuntimeError("SSH_KNOWN_HOSTS_FILE_NOT_FOUND")

    ssh_binary = shutil.which("ssh")

    if ssh_binary is None:
        raise RuntimeError("SSH_BINARY_NOT_FOUND")

    arguments = [
        ssh_binary,
        "-i",
        str(identity_file),
        "-o",
        "BatchMode=yes",
        "-o",
        "PasswordAuthentication=no",
        "-o",
        "KbdInteractiveAuthentication=no",
        "-o",
        "PreferredAuthentications=publickey",
        "-o",
        "IdentitiesOnly=yes",
        "-o",
        f"ConnectTimeout={connect_timeout}",
        "-o",
        "ServerAliveInterval=15",
        "-o",
        "ServerAliveCountMax=2",
        "-o",
        "StrictHostKeyChecking=yes",
        "-o",
        f"UserKnownHostsFile={known_hosts_file}",
        f"{username}@{host}",
        *command,
    ]

    result = subprocess.run(
        arguments,
        input=stdin_text,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        timeout=command_timeout,
        check=False,
    )

    if result.returncode != 0:
        error = result.stderr.strip()

        raise RuntimeError(
            "SSH_COMMAND_FAILED:"
            + str(result.returncode)
            + ":"
            + (error or "NO_STDERR")
        )

    return result.stdout
