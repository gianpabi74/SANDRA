from __future__ import annotations

from datetime import datetime, timezone
import unittest

from application.messages import Command, Query
from application.result import ApplicationResult
from application.ports.inbound import (
    CommandHandler,
    QueryHandler,
)
from application.ports.outbound import (
    EventBus,
    Repository,
    UnitOfWork,
)
from application.use_cases import UseCase


class ApplicationFoundationTests(
    unittest.TestCase
):
    def test_command_is_immutable_message(self) -> None:
        command = Command(
            message_id="message-1",
            correlation_id="correlation-1",
            created_at=datetime.now(timezone.utc),
        )

        self.assertEqual(
            command.message_id,
            "message-1",
        )

        with self.assertRaises(
            AttributeError
        ):
            command.message_id = "changed"  # type: ignore[misc]

    def test_query_requires_aware_timestamp(self) -> None:
        with self.assertRaises(
            ValueError
        ):
            Query(
                message_id="message-2",
                correlation_id="correlation-2",
                created_at=datetime.now(),
            )

    def test_success_result_rejects_error(self) -> None:
        with self.assertRaises(
            ValueError
        ):
            ApplicationResult[
                str
            ](
                success=True,
                code="OK",
                value="value",
                error="unexpected",
            )

    def test_failed_result_requires_error(self) -> None:
        with self.assertRaises(
            ValueError
        ):
            ApplicationResult[
                str
            ](
                success=False,
                code="FAILED",
            )

    def test_protocols_are_importable(self) -> None:
        self.assertIsNotNone(CommandHandler)
        self.assertIsNotNone(QueryHandler)
        self.assertIsNotNone(Repository)
        self.assertIsNotNone(EventBus)
        self.assertIsNotNone(UnitOfWork)
        self.assertIsNotNone(UseCase)


if __name__ == "__main__":
    unittest.main()
