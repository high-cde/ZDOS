#!/usr/bin/env python3
"""ZRetro: native ZDOS retro game IDE prototype."""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import shutil
import sys
from pathlib import Path

from hub import prepare_manifest

TARGETS = {
    "c64": {"name": "Commodore 64", "cpu": "6502", "artifact": ".prg", "backend": "cc65/ca65"},
    "atari8": {"name": "Atari 8-bit", "cpu": "6502", "artifact": ".xex", "backend": "cc65/ca65"},
    "amiga": {"name": "Amiga", "cpu": "68000", "artifact": ".adf", "backend": "vasm + disk builder"},
}
VALID = {"project", "target", "screen", "palette", "sprite", "scene", "text", "on", "player", "enemy", "sound", "end"}


def parse_source(path: Path) -> list[str]:
    lines = []
    for number, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        keyword = line.split(maxsplit=1)[0].lower()
        if keyword not in VALID:
            raise ValueError(f"{path}:{number}: parola ZRetro non ammessa: {keyword}")
        lines.append(line)
    if not any(line.lower().startswith("project ") for line in lines):
        raise ValueError("sorgente ZRetro senza dichiarazione project")
    if not any(line.lower().startswith("target ") for line in lines):
        raise ValueError("sorgente ZRetro senza target")
    return lines


def manifest(project: Path, source: Path, lines: list[str]) -> dict:
    targets = next(line.split()[1:] for line in lines if line.lower().startswith("target "))
    unsupported = sorted(set(targets) - TARGETS.keys())
    if unsupported:
        raise ValueError(f"target non supportati: {', '.join(unsupported)}")
    project_name = next(line.split(maxsplit=1)[1] for line in lines if line.lower().startswith("project "))
    source_hash = hashlib.sha256(source.read_bytes()).hexdigest()
    return {
        "schema": "zretro-project/v1",
        "name": project_name,
        "source": source.name,
        "source_sha256": source_hash,
        "targets": [{"id": target, **TARGETS[target]} for target in targets],
        "runtime": "zretro-terminal-v1",
        "native_language": "zlang-by-zdos",
        "security": {"filesystem": "project-root-only", "network": "disabled", "shell": "disabled"},
        "status": "VALIDATED",
    }


def compile_project(project: Path, source: Path) -> Path:
    lines = parse_source(source)
    data = manifest(project, source, lines)
    out = project / "build"
    out.mkdir(parents=True, exist_ok=True)
    (out / "game.zri.json").write_text(json.dumps({**data, "ir": lines}, indent=2) + "\n", encoding="utf-8")
    for target in data["targets"]:
        artifact = out / f"{data['name'].lower().replace(' ', '-')}-{target['id']}.zretro.json"
        artifact.write_text(json.dumps({"format": target["artifact"], "backend": target["backend"], "project": data["name"], "ir": lines}, indent=2) + "\n", encoding="utf-8")
    (out / "manifest.json").write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
    return out / "manifest.json"


def render(lines: list[str]) -> str:
    title = next((line.split(maxsplit=1)[1] for line in lines if line.lower().startswith("project ")), "ZRETRO")
    screen = [" " * 40 for _ in range(22)]
    screen[0] = "=" * 40
    screen[1] = f" {title[:36]:<36}"
    screen[2] = "=" * 40
    for line in lines:
        if line.lower().startswith("text "):
            value = line.split(maxsplit=1)[1].strip('"')[:38]
            screen[5] = f" {value:<38}"
        elif line.lower().startswith("player "):
            screen[10] = "                 ▲ PLAYER"
        elif line.lower().startswith("enemy "):
            screen[12] = "                         ◈ ENEMY"
    screen[19] = " " * 6 + "[ARROWS] MOVE  [SPACE] FIRE  [Q] QUIT"
    screen[20] = " " * 8 + "ZLANG RUNTIME // ZDOS NATIVE // READY"
    screen[21] = "=" * 40
    return "\n".join(screen)


def run_project(source: Path) -> int:
    lines = parse_source(source)
    print("\033[2J\033[H", end="")
    print(render(lines))
    print("\nZRETRO DEMO: runtime terminale attivo; input interattivo disponibile nella prossima milestone.")
    return 0


def init_project(root: Path, name: str) -> int:
    project = root / name.lower().replace(" ", "-")
    project.mkdir(parents=True, exist_ok=True)
    source = project / "main.zretro"
    source.write_text("\n".join([
        f"project {name}", "target c64 atari8 amiga", "screen 40 22", "palette c64",
        'text "ZRetro // FIRST ZDOS GAME"', 'player ship', 'enemy drone', 'on tick', 'end', ""
    ]), encoding="utf-8")
    print(f"ZRETRO_PROJECT_CREATED path={project} source={source}")
    return 0


def help_text() -> str:
    return "\n".join([
        "h                 aiuto",
        "n <nome>          nuovo progetto",
        "b <sorgente>      build C64/Atari/Amiga",
        "r <sorgente>      preview terminale",
        "t                 target supportati",
        "a                 asset del progetto",
        "q                 esci",
    ])


def console(root: Path) -> int:
    print("ZRETRO IDE // ZLANG BY ZDOS // C64 MODE")
    print("digita h per aiuto")
    while True:
        try:
            raw = input("x@zdos /zretro ")
        except EOFError:
            print()
            return 0
        raw = raw.strip()
        if not raw:
            continue
        parts = raw.split(maxsplit=1)
        command = parts[0].lower()
        argument = parts[1] if len(parts) > 1 else ""
        try:
            if command == "h":
                print(help_text())
            elif command == "q":
                return 0
            elif command == "t":
                for key, target in TARGETS.items():
                    print(f"{key:<8} {target['name']} CPU={target['cpu']} artifact={target['artifact']}")
            elif command == "a":
                print("ZRETRO ASSETS: palette, sprite, scene, sound")
            elif command == "p" and argument:
                source = Path(argument)
                build_manifest = source.parent / "build" / "manifest.json"
                if not build_manifest.is_file():
                    compile_project(source.parent, source)
                output = prepare_manifest(source.parent, build_manifest)
                print(f"ZRETRO_HUB_READY url=https://zdos-hub.it/ manifest={output}")
            elif command == "p":
                print("ZRETRO_ERROR p richiede il percorso di un file .zretro")
            elif command == "n" and argument:
                init_project(root, argument)
            elif command == "b" and argument:
                result = compile_project(Path(argument).parent, Path(argument))
                print(f"ZRETRO_BUILD_OK manifest={result}")
            elif command == "r" and argument:
                run_project(Path(argument))
            else:
                print("ZRETRO_ERROR comando o argomento non valido; usa h")
        except (OSError, ValueError) as exc:
            print(f"ZRETRO_ERROR {exc}")


def main() -> int:
    parser = argparse.ArgumentParser(prog="zretro", description="ZRetro IDE native ZDOS/Zlang")
    sub = parser.add_subparsers(dest="command", required=True)
    init = sub.add_parser("init"); init.add_argument("name"); init.add_argument("--root", default=".")
    build = sub.add_parser("build"); build.add_argument("source", type=Path)
    run = sub.add_parser("run"); run.add_argument("source", type=Path)
    repl = sub.add_parser("console"); repl.add_argument("--root", default=".")
    args = parser.parse_args()
    try:
        if args.command == "init": return init_project(Path(args.root), args.name)
        if args.command == "build":
            result = compile_project(args.source.parent, args.source)
            print(f"ZRETRO_BUILD_OK manifest={result}")
            return 0
        if args.command == "run": return run_project(args.source)
        return console(Path(args.root))
    except (OSError, ValueError) as exc:
        print(f"ZRETRO_ERROR {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
