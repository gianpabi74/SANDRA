"""Application use-case contracts.

Concrete use cases are intentionally absent from R3-000010.
"""

from .contract import UseCase
from .declare_desired_state import DeclareDesiredState
from .evaluate_policy_decision import EvaluatePolicyDecision
from .observe_subject import ObserveSubject
from .qualify_evidence import QualifyEvidence
from .query_resource_graph import QueryResourceGraph

__all__ = [
    "DeclareDesiredState",
    "EvaluatePolicyDecision",
    "ObserveSubject",
    "QualifyEvidence",
    "QueryResourceGraph",
    "UseCase",
]
