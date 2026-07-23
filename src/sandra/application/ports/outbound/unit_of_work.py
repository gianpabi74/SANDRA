"""Application transaction-boundary port."""

from __future__ import annotations

from types import TracebackType
from typing import Protocol, Self


class UnitOfWork(Protocol):
    """Control one atomic Application Layer consistency boundary."""

    def __enter__(self) -> Self:
        """Enter the consistency boundary."""
        ...

    def __exit__(
        self,
        exception_type: type[BaseException] | None,
        exception: BaseException | None,
        traceback: TracebackType | None,
    ) -> bool | None:
        """Close the boundary and preserve exception semantics."""
        ...

    def commit(self) -> None:
        """Commit all pending authoritative changes."""
        ...

    def rollback(self) -> None:
        """Discard all pending authoritative changes."""
        ...
