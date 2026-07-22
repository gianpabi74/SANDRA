import os
import pathlib
import shutil
import stat
import subprocess
import tempfile


def execute_ssh(
    host: str,
    username: str,
    password: str,
    command: list[str],
    *,
    stdin_text: str = "",
    connect_timeout: int = 10,
    command_timeout: int = 120,
) -> str:
    if not host:
        raise ValueError("HOST_EMPTY")

    if not username:
        raise ValueError("USERNAME_EMPTY")

    if not password:
        raise ValueError("PASSWORD_EMPTY")

    if not isinstance(command, list) or not command:
        raise ValueError("COMMAND_INVALID")

    ssh_binary = shutil.which("ssh")
    setsid_binary = shutil.which("setsid")

    if ssh_binary is None:
        raise RuntimeError("SSH_BINARY_NOT_FOUND")

    if setsid_binary is None:
        raise RuntimeError("SETSID_BINARY_NOT_FOUND")

    with tempfile.TemporaryDirectory(
        prefix="sandra-linux-ssh-"
    ) as temporary_directory:
        temporary_root = pathlib.Path(temporary_directory)
        askpass_path = temporary_root / "askpass.sh"
        known_hosts_path = temporary_root / "known_hosts"

        askpass_path.write_text(
            "#!/usr/bin/env sh\n"
            "printf '%s\\n' \"$SANDRA_SSH_PASSWORD\"\n",
            encoding="utf-8",
        )

        askpass_path.chmod(
            stat.S_IRUSR
            | stat.S_IWUSR
            | stat.S_IXUSR
        )

        environment = os.environ.copy()
        environment.update(
            {
                "DISPLAY": ":0",
                "SSH_ASKPASS": str(askpass_path),
                "SSH_ASKPASS_REQUIRE": "force",
                "SANDRA_SSH_PASSWORD": password,
            }
        )

        arguments = [
            setsid_binary,
            "-w",
            ssh_binary,
            "-o",
            "BatchMode=no",
            "-o",
            "PreferredAuthentications=password,keyboard-interactive",
            "-o",
            "PubkeyAuthentication=no",
            "-o",
            "NumberOfPasswordPrompts=1",
            "-o",
            f"ConnectTimeout={connect_timeout}",
            "-o",
            "ServerAliveInterval=15",
            "-o",
            "ServerAliveCountMax=2",
            "-o",
            "StrictHostKeyChecking=accept-new",
            "-o",
            f"UserKnownHostsFile={known_hosts_path}",
            f"{username}@{host}",
            "--",
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
            env=environment,
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
