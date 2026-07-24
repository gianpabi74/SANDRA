"""Application use-case contracts.

Concrete use cases are intentionally absent from R3-000010.
"""

from .contract import UseCase
from .declare_desired_state import DeclareDesiredState
from .observe_subject import ObserveSubject
from .qualify_evidence import QualifyEvidence
from .query_resource_graph import QueryResourceGraph

__all__ = [
    "DeclareDesiredState",
    "ObserveSubject",
    "QualifyEvidence",
    "QueryResourceGraph",
    "UseCase",
]
