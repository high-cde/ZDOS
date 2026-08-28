# ZDOS Unified Ecosystem Architecture

This document outlines the structure of the unified **ZDOS** repository, consolidating all Z-GENESIS and ZDOS-related projects into a single, functional monorepo.

## Directory Structure

```text
ZDOS/
├── core/                # Neural Cortex, AAAK, and Memory Systems
│   ├── cortex/          # Z-GENESIS-CORTEX logic
│   ├── aaak/            # Autonomous Agent Access Kernel
│   └── memory/          # memzdos high-performance memory
├── os/                  # Operating System and Kernel
│   └── x86_64/          # Verifiable bare-metal kernel and ZLB2 runtime
├── network/             # DSN and Node infrastructure
│   ├── nodes/           # Z-GENESIS-NODES
│   └── dsn/             # Distributed Service Network logic
├── interface/           # User Interfaces
│   ├── cli/             # Z-GENESIS-CLI (zgenctl)
│   └── web/             # Local read-only status interface
├── dev/                 # Development Tools and SDKs
│   ├── zen/             # ZEN- Programming Hub
│   └── scripts/         # Unified build and deployment scripts
└── docs/                # Consolidated documentation
```

## Integration Strategy

1.  **Shared Core**: The `core/` directory contains libraries and research modules; only components with code and tests are treated as implemented.
2.  **Unified CLI**: The `zgenctl` manages the explicitly supported local commands and does not claim remote orchestration.
3.  **Global Build System**: Build scripts compile only declared, verifiable targets and fail when a required dependency is absent.
4.  **Data Persistence**: Persistence is local to the component that owns it; no DSN-PALACE or distributed ledger is assumed unless an implementation and test exist.

## Branding

Following the user preference, all components will be unified under the **ZDOS** brand, ensuring a professional and cohesive identity.
