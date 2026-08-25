from dataclasses import dataclass
from enum import Enum, auto
from typing import Any, Dict


class CyberSignalType(Enum):
    RISK_ASSESSMENT = auto()
    INCIDENT = auto()
    THREAT_INTEL = auto()
    COMPLIANCE = auto()
    ARCHITECTURE = auto()


@dataclass
class CyberSignal:
    type: CyberSignalType
    payload: Dict[str, Any]
    context: Dict[str, Any]


class CyberCortex:
    """
    CORTEX Cybersecurity:
    - organizza conoscenza
    - valuta rischi
    - instrada segnali
    - mantiene coerenza con legalità ed etica
    """

    def __init__(self) -> None:
        self.knowledge_graph: Dict[str, Any] = {}
        self.policies: Dict[str, Any] = {}

    def ingest_signal(self, signal: CyberSignal) -> Dict[str, Any]:
        if signal.type is CyberSignalType.RISK_ASSESSMENT:
            return self._handle_risk_assessment(signal)
        if signal.type is CyberSignalType.INCIDENT:
            return self._handle_incident(signal)
        if signal.type is CyberSignalType.THREAT_INTEL:
            return self._handle_threat_intel(signal)
        if signal.type is CyberSignalType.COMPLIANCE:
            return self._handle_compliance(signal)
        if signal.type is CyberSignalType.ARCHITECTURE:
            return self._handle_architecture(signal)
        return {"status": "ignored", "reason": "unknown_signal_type"}

    def _handle_risk_assessment(self, signal: CyberSignal) -> Dict[str, Any]:
        return {
            "mode": "risk_assessment",
            "summary": "Valutazione del rischio basata su asset, minacce e impatti (solo difensivo).",
        }

    def _handle_incident(self, signal: CyberSignal) -> Dict[str, Any]:
        return {
            "mode": "incident_response",
            "summary": "Fasi di risposta: identificazione, contenimento, eradicazione, recupero.",
        }

    def _handle_threat_intel(self, signal: CyberSignal) -> Dict[str, Any]:
        return {
            "mode": "threat_intel",
            "summary": "Classificazione delle minacce e correlazione con il knowledge graph.",
        }

    def _handle_compliance(self, signal: CyberSignal) -> Dict[str, Any]:
        return {
            "mode": "compliance",
            "summary": "Allineamento concettuale a normative (ISO 27001, NIST, GDPR).",
        }

    def _handle_architecture(self, signal: CyberSignal) -> Dict[str, Any]:
        return {
            "mode": "security_architecture",
            "summary": "Raccomandazioni di architettura difensiva (zero trust, least privilege, segmentazione).",
        }
