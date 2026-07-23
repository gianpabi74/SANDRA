"""Application use-case contracts.

Concrete use cases are intentionally absent from R3-000010.
"""

from .contract import UseCase
from .observe_subject import ObserveSubject

__all__ = [
    "ObserveSubject",
    "UseCase",
]
