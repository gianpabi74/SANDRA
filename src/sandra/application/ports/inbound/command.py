"""Inbound command port contract."""

from __future__ import annotations

from typing import Protocol, TypeVar

from application.messages import Command
from application.result import ApplicationResult


CommandType = TypeVar(
    "CommandType",
    bound=Command,
    contravariant=True,
)
CommandResult = TypeVar(
    "CommandResult",
    covariant=True,
)


class CommandHandler(
    Protocol[CommandType, CommandResult]
):
    """Handle one technology-independent command."""

    def handle(
        self,
        command: CommandType,
    ) -> ApplicationResult[CommandResult]:
        """Execute the command use case."""
        ...
