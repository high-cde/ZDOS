from typing import Any, Dict

# Router principali
from zdos_neuro_router import NeuroRouter
from zdos_neuro_quantum_router import QuantumRouter

# Moduli cognitivi
from zdos_neuro_aaak import AAAK

# Moduli DSN
from zdos_neuro_dsn_live import DSNLive

# Modulo Cybersecurity
from zdos_neuro_cortex_cyber import CyberCortex, CyberSignal, CyberSignalType

# Moduli avanzati
from zdos_neuro_pipelines import NeuroPipelines
from zdos_neuro_quantum_field import QuantumFieldViewer
from zdos_neuro_participation import ParticipationEngine

# Moduli evolutivi
from zdos_neuro_cortex_fusion import CortexFusionLayer
from zdos_neuro_memory import NeuroMemory
from zdos_neuro_self_healing import QuantumSelfHealer


class CortexUnified:
    """
    CORTEX PRINCIPALE ZDOS‑NEURO
    - Router modulare
    - Quantum Router
    - CyberCortex
    - AAAK
    - DSN‑LIVE
    - Neuro‑Pipelines
    - Quantum Field Viewer
    - Participation Engine
    - Fusion Layer
    - Memory Engine
    - Self‑Healing
    """

    def __init__(self):
        # Router principali
        self.router = NeuroRouter()
        self.qrouter = QuantumRouter()

        # Moduli cognitivi
        self.aaak = AAAK()

        # Moduli DSN
        self.dsn = DSNLive()

        # Moduli avanzati
        self.pipelines = NeuroPipelines()
        self.qfield = QuantumFieldViewer()
        self.participation = ParticipationEngine()

        # Moduli evolutivi
        self.fusion = CortexFusionLayer()
        self.memory = NeuroMemory()
        self.healer = QuantumSelfHealer()

        # Modulo Cybersecurity
        self.cyber = CyberCortex()

    def ingest(self, signal: Dict[str, Any]) -> Dict[str, Any]:
        """
        Punto di ingresso generale del CORTEX.
        """

        # 1. Memorizza sempre il segnale
        self.memory.store(signal)

        # 2. Participation Engine (osserva/modifica)
        signal = self.participation.process(signal)

        # 3. Quantum Router (priorità alta)
        out = self.qrouter.route(self, signal)
        if out.get("status") != "unhandled":
            return self.healer.heal(out)

        # 4. Router modulare classico
        out = self.router.dispatch(self, signal)
        return self.healer.heal(out)

    # -------------------------
    # ROUTING DEI MODULI
    # -------------------------

    # CyberCortex
    def route_cyber(self, signal):
        if signal.get("domain") == "cybersecurity":
            return self.cyber.ingest_signal(
                CyberSignal(
                    type=signal["payload"].get("type", CyberSignalType.THREAT_INTEL),
                    payload=signal["payload"],
                    context=signal["context"]
                )
            )
        return None

    # AAAK
    def route_aaak(self, signal):
        if signal.get("domain") == "aaak":
            return self.aaak.compress(signal["payload"])
        return None

    # DSN‑LIVE
    def route_dsn(self, signal):
        if signal.get("domain") == "dsn":
            return self.dsn.ingest(signal)
        return None

    # Neuro‑Pipelines
    def route_pipeline(self, signal):
        if signal.get("domain") == "pipeline":
            name = signal["payload"].get("pipeline")
            return self.pipelines.run(name, signal)
        return None

    # Quantum Field Viewer
    def route_qfield(self, signal):
        if signal.get("domain") == "qfield":
            return self.qfield.render(signal)
        return None

    # Participation Engine (già applicato in ingest)
    def route_participation(self, signal):
        if signal.get("domain") == "participation":
            return self.participation.process(signal)
        return None

    # Fusion Layer
    def route_fusion(self, signal):
        if signal.get("domain") == "fusion":
            aaak_out = self.route_aaak({"domain": "aaak", "payload": signal["payload"], "context": signal["context"]})
            dsn_out = self.route_dsn({"domain": "dsn", "payload": signal["payload"], "context": signal["context"]})
            cyber_out = self.route_cyber({"domain": "cybersecurity", "payload": signal["payload"], "context": signal["context"]})
            return self.fusion.fuse(aaak_out, dsn_out, cyber_out)
        return None
