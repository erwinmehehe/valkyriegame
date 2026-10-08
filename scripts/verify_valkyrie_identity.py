#!/usr/bin/env python3
"""Fail closed when the canonical Valkyrie sprite identity changes.

The independent hashes below intentionally do not come from an editable art
manifest: a manifest update must not silently bless a new character.
"""
from __future__ import annotations

import argparse
import hashlib
from pathlib import Path
import struct
import sys

ROOT = Path(__file__).resolve().parents[1]
ATLAS = ROOT / "ValkyrieLearn/Resources/Valkyrie.atlas"
CANONICAL_SHA256 = {
    "idle_01.png": "9c23d5bb34259368ca095ed3fc3a4d674b7197c1f1f753d09129e81b45c3ba2f",
    "walk_01.png": "9f2c5ef3611e842fa272e8d1c2e65fa89243176b378ae5745bf66d88119d25aa",
    "walk_02.png": "bb8b45905c5de6ee6c9dd41a69259e7fbda6528a4a196cde84894bd4e0a43e7c",
    "interact_01.png": "9ac9b89e6e0b0a6c790745b36a68a613df628fd464c9de2dec3dbd50982235e4",
    "celebrate_01.png": "9c23d5bb34259368ca095ed3fc3a4d674b7197c1f1f753d09129e81b45c3ba2f",
    "react_01.png": "9c23d5bb34259368ca095ed3fc3a4d674b7197c1f1f753d09129e81b45c3ba2f",
}
EXPECTED_CANVAS = (370, 480)
# Changes to these are intentionally not part of a room/background-art PR.
# A future explicitly approved character change must be handled separately.
PROTECTED_CODE = {
    "ValkyrieLearn/Game/Actors/ValkyrieNode.swift",
    "ValkyrieLearn/Game/Systems/ArtSystem.swift",
    "ValkyrieLearn/Resources/V331_ART_MANIFEST.json",
}

def verify_atlas() -> list[str]:
    errors = []
    actual = {p.name for p in ATLAS.glob("*") if p.is_file()}
    expected = set(CANONICAL_SHA256)
    if actual != expected:
        errors.append(f"Atlas filename set changed: missing={sorted(expected - actual)} extra={sorted(actual - expected)}")
    for name, digest in CANONICAL_SHA256.items():
        path = ATLAS / name
        if not path.is_file():
            errors.append(f"Missing canonical frame: {name}")
            continue
        data = path.read_bytes()
        if hashlib.sha256(data).hexdigest() != digest:
            errors.append(f"Unapproved Valkyrie sprite modification: {name}")
        if not data.startswith(b"\x89PNG\r\n\x1a\n") or len(data) < 24:
            errors.append(f"Invalid PNG: {name}")
        elif struct.unpack(">II", data[16:24]) != EXPECTED_CANVAS:
            errors.append(f"Wrong pose canvas dimensions: {name}")
    return errors

def verify_pr_changes(paths: list[str]) -> list[str]:
    errors = []
    for raw_path in paths:
        path = raw_path.strip().replace("\\", "/")
        if not path:
            continue
        lower = path.lower()
        if path.startswith("ValkyrieLearn/Resources/Valkyrie.atlas/"):
            errors.append(f"Valkyrie sprite atlas is locked: {path}")
        elif path in PROTECTED_CODE:
            errors.append(f"Character rendering/art-provenance file needs separate explicit approval: {path}")
        elif (lower.startswith("valkyrielearn/resources/") and
              "valkyrie" in lower.removeprefix("valkyrielearn/resources/")):
            errors.append(f"New Valkyrie-looking asset must not be added in room-art changes: {path}")
    return errors

def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--changed-stdin", action="store_true",
                        help="Also reject character changes among newline-delimited PR paths")
    args = parser.parse_args()
    errors = verify_atlas()
    if args.changed_stdin:
        errors += verify_pr_changes(sys.stdin.read().splitlines())
    if errors:
        for error in errors:
            print("FAIL Valkyrie identity lock: " + error, file=sys.stderr)
        return 1
    print("PASS Valkyrie's six exact approved atlas frames and 370x480 canvas are unchanged.")
    if args.changed_stdin:
        print("PASS PR does not change protected Valkyrie artwork or rendering files.")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
