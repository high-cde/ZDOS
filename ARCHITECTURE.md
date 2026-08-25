# ZDOS Unified Ecosystem Architecture

This document outlines the structure of the unified **ZDOS** repository, consolidating all Z-GENESIS and ZDOS-related projects into a single, functional monorepo.

## Directory Structure

```text
ZDOS/
├── core/                # Neural Cortex, AAAK, and Memory Systems
│   ├── cortex/          # Z-GENESIS-CORTEX logic
│   ├── aaak/            # Autonomous Agent Access Kernel
│           ├── memory/          # memzdos high-performance memory
        └── primordia/         # ZDOS // PRIMORDIA - The Self-Generating Core
├── os/                  # Operating System and Kernel
│   ├── kernel/          # z.OS (CollapseOS fork)
│   └── ghostnet/        # Quantum Ghostnet OS components
├── network/             # DSN and Node infrastructure
│   ├── nodes/           # Z-GENESIS-NODES
│   └── dsn/             # Distributed Service Network logic
├── interface/           # User Interfaces
│   ├── cli/             # Z-GENESIS-CLI (zgenctl)
│   ├── web/             # Z-GENESIS-LIVE (Web Dashboard)
│   └── cloud/           # xCLOUD Enterprise Portal
├── dev/                 # Development Tools and SDKs
│   ├── zen/             # ZEN- Programming Hub
│   └── scripts/         # Unified build and deployment scripts
└── docs/                # Consolidated documentation
```

## Integration Strategy

1.  **Shared Core**: The `core/` directory will serve as the brain of the system, with `primordia/` acting as the self-generating core, providing neural routing and memory services to other modules.
2.  **Unified CLI**: The `zgenctl` will be updated to manage all modules within the monorepo.
3.  **Global Build System**: A root-level `Makefile` or `build.sh` will orchestrate the compilation and deployment of various components.
4.  **Data Persistence**: Centralized database management (DSN-PALACE) within the `core/` or `network/` layer.

## Branding

Following the user preference, all components will be unified under the **ZDOS** brand, ensuring a professional and cohesive identity.
