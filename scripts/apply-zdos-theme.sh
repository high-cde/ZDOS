#!/usr/bin/env bash
set -Eeuo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
WEB="$ROOT/web/index.html"
INTERFACE_CSS="$ROOT/interface/web/web/css/style.css"
MARKER="/* ZDOS THEME: parrot-backbox fusion */"

[ -f "$WEB" ]
[ -f "$INTERFACE_CSS" ]

# Inline portal: replace only design tokens, preserving markup and behavior.
sed -i \
  -e 's/--bg-color: #[0-9a-fA-F]*/--bg-color: #080B12/' \
  -e 's/--panel-bg: #[0-9a-fA-F]*/--panel-bg: #101722/' \
  -e 's/--border-color: #[0-9a-fA-F]*/--border-color: #263449/' \
  -e 's/--accent-green: #[0-9a-fA-F]*/--accent-green: #10B981/' \
  -e 's/--accent-blue: #[0-9a-fA-F]*/--accent-blue: #22D3EE/' \
  -e 's/--text-main: #[0-9a-fA-F]*/--text-main: #F8FAFC/' \
  -e 's/--text-muted: #[0-9a-fA-F]*/--text-muted: #94A3B8/' \
  -e "s/font-family: 'Segoe UI', Roboto, Helvetica, Arial, sans-serif/font-family: Inter, system-ui, sans-serif/" \
  -e "s/font-family: 'Courier New', monospace/font-family: 'JetBrains Mono', 'Courier New', monospace/g" \
  "$WEB"

# Shared interface stylesheet: append once, so running this command again is safe.
if ! grep -Fq "$MARKER" "$INTERFACE_CSS"; then
  cat >> "$INTERFACE_CSS" <<'CSS'

/* ZDOS THEME: parrot-backbox fusion */
:root {
  --zdos-bg: #080B12;
  --zdos-surface: #101722;
  --zdos-surface-2: #162235;
  --zdos-blue: #2563EB;
  --zdos-cyan: #22D3EE;
  --zdos-violet: #8B5CF6;
  --zdos-green: #10B981;
  --zdos-amber: #F59E0B;
  --zdos-red: #EF4444;
  --zdos-text: #F8FAFC;
  --zdos-muted: #94A3B8;
}

html { background: var(--zdos-bg); }
body {
  background: radial-gradient(circle at 15% 0%, rgba(37,99,235,.16), transparent 34rem),
              linear-gradient(135deg, var(--zdos-bg), #0B1220 55%, #120D24);
  color: var(--zdos-text);
  font-family: Inter, system-ui, sans-serif;
  min-height: 100vh;
}

button, input, select, textarea { font: inherit; }
::selection { background: rgba(34,211,238,.35); color: #fff; }
CSS
fi

printf 'ZDOS_THEME_APPLIED web=%s interface=%s\n' "$WEB" "$INTERFACE_CSS"
