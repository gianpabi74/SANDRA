"""Deterministic Application Layer result envelope."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Generic, TypeVar


ResultValue = TypeVar("ResultValue")


@dataclass(frozen=True, slots=True)
class ApplicationResult(Generic[ResultValue]):
    """Result returned by an inbound Application port."""

    success: bool
    code: str
    value: ResultValue | None = None
    error: str | None = None

    def __post_init__(self) -> None:
        if not self.code:
            raise ValueError("code must not be empty")

        if self.success and self.error is not None:
            raise ValueError(
                "successful result cannot contain an error"
            )

        if not self.success and not self.error:
            raise ValueError(
                "failed result must contain an error"
            )

    @classmethod
    def ok(
        cls,
        code: str,
        value: ResultValue | None = None,
    ) -> "ApplicationResult[ResultValue]":
        """Create a successful result."""

        return cls(
            success=True,
            code=code,
            value=value,
        )

    @classmethod
    def fail(
        cls,
        code: str,
        error: str,
    ) -> "ApplicationResult[ResultValue]":
        """Create a failed result."""

        return cls(
            success=False,
            code=code,
            error=error,
        )
