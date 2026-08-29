#!/usr/bin/env python3
"""Local ZDOS identity bootstrap and role-capability verifier.

The IP address is deliberately absent from every identity artifact.
"""
from __future__ import annotations

import argparse
import base64
import getpass
import hashlib
import hmac
import json
import os
import secrets
import string
import subprocess
import sys
import tempfile
import time
from pathlib import Path

ALPHABET = string.ascii_letters + string.digits
ROLES = {"standard", "operator", "administrator"}
PBKDF2_ROUNDS = 600_000


def canonical(value: object) -> bytes:
    return json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode("utf-8")


def run_openssl(*args: str, input_text: str | None = None) -> bytes:
    result = subprocess.run(
        ["openssl", *args],
        input=input_text.encode() if input_text is not None else None,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if result.returncode:
        raise RuntimeError(result.stderr.decode("utf-8", errors="replace").strip() or "openssl failed")
    return result.stdout


def recovery_code() -> str:
    return "".join(secrets.choice(ALPHABET) for _ in range(36))


def hash_recovery(code: str, salt: bytes) -> str:
    return hashlib.pbkdf2_hmac("sha256", code.encode("utf-8"), salt, PBKDF2_ROUNDS).hex()


def passphrase(confirm: bool = False) -> str:
    value = os.environ.get("ZDOS_IDENTITY_PASSPHRASE")
    if value is None:
        value = getpass.getpass("Passphrase chiave privata ZDOS: ")
    if not value:
        raise ValueError("la passphrase non può essere vuota")
    if confirm and "ZDOS_IDENTITY_PASSPHRASE" not in os.environ:
        again = getpass.getpass("Ripeti passphrase: ")
        if value != again:
            raise ValueError("le passphrase non coincidono")
    return value


def init_identity(args: argparse.Namespace) -> int:
    if args.role not in ROLES:
        raise ValueError(f"ruolo non valido: {args.role}")
    state = Path(args.state_dir).expanduser().resolve()
    if state.exists() and any(state.iterdir()):
        raise FileExistsError(f"directory identità non vuota: {state}")
    state.mkdir(parents=True, exist_ok=True)
    state.chmod(0o700)
    secret = passphrase(confirm=True)
    code = recovery_code()
    salt = secrets.token_bytes(16)
    private_plain = state / ".private-key.plain.pem"
    private_key = state / "private-key.pem.enc"
    public_key = state / "public-key.pem"
    try:
        run_openssl("genpkey", "-algorithm", "Ed25519", "-out", str(private_plain))
        private_plain.chmod(0o600)
        run_openssl(
            "pkcs8", "-topk8", "-v2", "aes-256-cbc", "-iter", "600000",
            "-passout", "env:ZDOS_IDENTITY_PASSPHRASE", "-in", str(private_plain), "-out", str(private_key),
            input_text=None,
        ) if os.environ.get("ZDOS_IDENTITY_PASSPHRASE") else _encrypt_with_passphrase(private_plain, private_key, secret)
        private_key.chmod(0o600)
        run_openssl("pkey", "-in", str(private_plain), "-pubout", "-out", str(public_key))
        public_key.chmod(0o644)
        public_bytes = public_key.read_bytes()
        identity_id = "did:zdos:" + hashlib.sha256(public_bytes).hexdigest()
        payload = {
            "schema": "zdos-role-grant/v1",
            "subject": identity_id,
            "role": args.role,
            "nick": args.nick,
            "issued_at": int(time.time()),
            "issuer": "zdos-bootstrap",
        }
        payload_path = state / ".role-payload.json"
        signature_path = state / ".role-signature.bin"
        payload_path.write_bytes(canonical(payload))
        run_openssl("pkeyutl", "-sign", "-inkey", str(private_plain), "-rawin", "-in", str(payload_path), "-out", str(signature_path))
        signature = base64.b64encode(signature_path.read_bytes()).decode("ascii")
        profile = {
            "schema": "zdos-identity/v1",
            "identity": identity_id,
            "nick": args.nick,
            "role": args.role,
            "public_key": "public-key.pem",
            "role_grant": {"payload": payload, "signature_base64": signature, "algorithm": "Ed25519"},
            "recovery": {
                "algorithm": "PBKDF2-HMAC-SHA256",
                "rounds": PBKDF2_ROUNDS,
                "salt_base64": base64.b64encode(salt).decode("ascii"),
                "digest_hex": hash_recovery(code, salt),
            },
            "network_identity": "none",
        }
        (state / "identity.json").write_text(json.dumps(profile, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        (state / "identity.json").chmod(0o600)
        print(f"ZDOS_IDENTITY_CREATED identity={identity_id} nick={args.nick} role={args.role}")
        print(f"ZDOS_RECOVERY_CODE={code}")
        print("ZDOS_RECOVERY_WARNING=conservare il codice offline; non viene salvato in chiaro")
        return 0
    finally:
        for path in (private_plain, state / ".role-payload.json", state / ".role-signature.bin"):
            path.unlink(missing_ok=True)


def _encrypt_with_passphrase(source: Path, target: Path, secret: str) -> None:
    env = os.environ.copy()
    env["ZDOS_IDENTITY_PASSPHRASE"] = secret
    result = subprocess.run(
        ["openssl", "pkcs8", "-topk8", "-v2", "aes-256-cbc", "-iter", "600000", "-passout", "env:ZDOS_IDENTITY_PASSPHRASE", "-in", str(source), "-out", str(target)],
        env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False,
    )
    if result.returncode:
        raise RuntimeError(result.stderr.decode("utf-8", errors="replace").strip() or "private key encryption failed")


def load_profile(state_dir: str) -> tuple[Path, dict]:
    state = Path(state_dir).expanduser().resolve()
    profile_path = state / "identity.json"
    profile = json.loads(profile_path.read_text(encoding="utf-8"))
    if profile.get("schema") != "zdos-identity/v1" or profile.get("network_identity") != "none":
        raise ValueError("profilo identità non valido o contiene un'identità di rete")
    return state, profile


def verify_identity(args: argparse.Namespace) -> int:
    state, profile = load_profile(args.state_dir)
    public_key = state / profile["public_key"]
    payload = state / ".verify-payload.json"
    signature = state / ".verify-signature.bin"
    payload.write_bytes(canonical(profile["role_grant"]["payload"]))
    signature.write_bytes(base64.b64decode(profile["role_grant"]["signature_base64"]))
    try:
        run_openssl("pkeyutl", "-verify", "-pubin", "-inkey", str(public_key), "-rawin", "-in", str(payload), "-sigfile", str(signature))
    finally:
        payload.unlink(missing_ok=True)
        signature.unlink(missing_ok=True)
    expected = "did:zdos:" + hashlib.sha256(public_key.read_bytes()).hexdigest()
    if not hmac.compare_digest(expected, profile["identity"]):
        raise ValueError("fingerprint identità non corrisponde alla chiave pubblica")
    print(f"ZDOS_IDENTITY_VERIFIED identity={profile['identity']} role={profile['role']}")
    return 0


def verify_recovery(args: argparse.Namespace) -> int:
    _, profile = load_profile(args.state_dir)
    code = os.environ.get("ZDOS_RECOVERY_CODE")
    if not code:
        raise ValueError("fornire ZDOS_RECOVERY_CODE nell'ambiente; non usare argomenti shell per segreti")
    if len(code) != 36 or any(char not in ALPHABET for char in code):
        raise ValueError("codice recovery non valido")
    recovery = profile["recovery"]
    salt = base64.b64decode(recovery["salt_base64"])
    actual = hash_recovery(code, salt)
    if not hmac.compare_digest(actual, recovery["digest_hex"]):
        raise ValueError("codice recovery rifiutato")
    print("ZDOS_RECOVERY_VERIFIED")
    return 0


def parser() -> argparse.ArgumentParser:
    root = argparse.ArgumentParser(description="ZDOS local identity and signed role capability")
    sub = root.add_subparsers(dest="command", required=True)
    create = sub.add_parser("init", help="crea una identità locale")
    create.add_argument("--nick", required=True)
    create.add_argument("--role", choices=sorted(ROLES), default="standard")
    create.add_argument("--state-dir", required=True)
    create.set_defaults(func=init_identity)
    for name, func in (("verify", verify_identity), ("verify-recovery", verify_recovery)):
        check = sub.add_parser(name)
        check.add_argument("--state-dir", required=True)
        check.set_defaults(func=func)
    return root


def main() -> int:
    try:
        args = parser().parse_args()
        return args.func(args)
    except (FileExistsError, FileNotFoundError, ValueError, RuntimeError, json.JSONDecodeError) as exc:
        print(f"ZDOS_IDENTITY_ERROR: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
