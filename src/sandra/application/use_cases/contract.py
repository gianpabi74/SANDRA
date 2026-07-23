"""Generic technology-independent use-case contract."""

from __future__ import annotations

from typing import Protocol, TypeVar


Request = TypeVar(
    "Request",
    contravariant=True,
)
Response = TypeVar(
    "Response",
    covariant=True,
)


class UseCase(
    Protocol[Request, Response]
):
    """Execute one bounded Application Layer responsibility."""

    def execute(
        self,
        request: Request,
    ) -> Response:
        """Execute the use case."""
        ...
