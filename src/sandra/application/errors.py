"""Technology-independent Application Layer errors."""

from __future__ import annotations


class ApplicationError(Exception):
    """Base error for Application Layer failures."""


class ApplicationValidationError(ApplicationError):
    """Input message or use-case contract is invalid."""


class ApplicationPreconditionError(ApplicationError):
    """A required precondition was not satisfied."""


class ApplicationConflictError(ApplicationError):
    """The request conflicts with a newer or concurrent state."""
