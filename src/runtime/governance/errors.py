"""Domain errors raised by the governance runtime."""


class GovernanceError(Exception):
    """Base class for deterministic governance runtime errors."""


class ResourceValidationError(GovernanceError):
    """Raised when a canonical resource violates its contract."""


class UnsupportedResourceError(GovernanceError):
    """Raised when a resource kind or API version is unsupported."""
