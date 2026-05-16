from typing import Any, Dict


class CortexFusionLayer:
    """
    Fonde output di AAAK, DSN e CyberCortex in una vista unica.
    """

    def fuse(self, aaak_out: Dict[str, Any], dsn_out: Dict[str, Any], cyber_out: Dict[str, Any]) -> Dict[str, Any]:
        return {
            "mode": "cortex_fusion",
            "aaak": aaak_out,
            "dsn": dsn_out,
            "cyber": cyber_out,
        }
