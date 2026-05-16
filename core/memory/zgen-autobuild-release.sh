#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-0.0.1}"

echo "=== ZGEN AUTOBUILD ZDOS-NEURO v$VERSION ==="

# 1. Verifica stato git
git status
echo
read -p "Controlla sopra. Continua? [y/N] " ans
[ "$ans" = "y" ] || exit 1

# 2. Rigenera README e CHANGELOG se hai generatori dedicati (placeholder)
# ./scripts/gen_readme.py
# ./scripts/gen_changelog.py

# 3. Aggiorna versione in pyproject.toml
python - <<EOF
from pathlib import Path
p = Path("pyproject.toml")
txt = p.read_text()
import re
txt = re.sub(r'version\s*=\s*"[0-9]+\.[0-9]+\.[0-9]+"',
             f'version = "{ "$VERSION" }"', txt)
p.write_text(txt)
EOF

# 4. Commit
git add pyproject.toml README.md CHANGELOG.md
git commit -m "Release zdos-neuro v$VERSION"

# 5. Tag
git tag -a "v$VERSION" -m "zdos-neuro v$VERSION"

# 6. Push branch + tag
git push
git push origin "v$VERSION"

echo "=== AUTOBUILD COMPLETATO: v$VERSION ==="
