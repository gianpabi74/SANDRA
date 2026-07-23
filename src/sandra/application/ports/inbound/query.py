"""Inbound query port contract."""

from __future__ import annotations

from typing import Protocol, TypeVar

from application.messages import Query
from application.result import ApplicationResult


QueryType = TypeVar(
    "QueryType",
    bound=Query,
    contravariant=True,
)
QueryResult = TypeVar(
    "QueryResult",
    covariant=True,
)


class QueryHandler(
    Protocol[QueryType, QueryResult]
):
    """Handle one technology-independent query."""

    def handle(
        self,
        query: QueryType,
    ) -> ApplicationResult[QueryResult]:
        """Execute the query use case."""
        ...
