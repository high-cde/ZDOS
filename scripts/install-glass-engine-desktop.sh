#!/usr/bin/env bash
set -Eeuo pipefail
APP_NAME="ZDOS Glass Engine"
DESKTOP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
DESKTOP_FILE="$DESKTOP_DIR/zdos-glass-engine.desktop"
mkdir -p "$DESKTOP_DIR"
cat > "$DESKTOP_FILE" <<'EOF'
[Desktop Entry]
Type=Application
Name=ZDOS Glass Engine
Comment=ZDOS Evidence Wallet, Browser Workbench e Zlang Studio
Exec=xdg-open http://127.0.0.1:8080/#top
Icon=utilities-terminal
Terminal=false
Categories=Development;Security;System;
StartupNotify=true
EOF
chmod 0644 "$DESKTOP_FILE"
command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$DESKTOP_DIR" || true
echo "Applicazione desktop installata: $DESKTOP_FILE"
echo "Avvia dal menu applicazioni: ZDOS Glass Engine"
echo "Il servizio resta su 127.0.0.1:8080 per non esporre wallet e identità sulla rete."
