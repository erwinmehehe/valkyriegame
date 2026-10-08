#!/usr/bin/env python3
"""Fail environment-art PRs that silently replace the canonical Valkyrie character."""
from pathlib import Path
import os
import subprocess
import sys

PROTECTED = (
    "ValkyrieLearn/Resources/Valkyrie.atlas/",
    "ValkyrieLearn/Resources/V331_ART_MANIFEST.json",
    "ValkyrieLearn/Game/Characters/ValkyrieNode.swift",
)
base = os.environ.get("VALKYRIE_PR_BASE", "").strip()
if not base:
    print("No pull-request base; approved original art hashes checked by validate_native.py")
    sys.exit(0)

subprocess.run(
    ["git", "fetch", "--no-tags", "--depth=1", "origin", base],
    check=True,
    stdout=subprocess.DEVNULL,
)
changes = subprocess.check_output(
    ["git", "diff", "--name-only", "FETCH_HEAD", "HEAD"], text=True
).splitlines()
blocked = [p for p in changes if p.startswith(PROTECTED)]
if blocked:
    print("BLOCKED: Valkyrie identity files require a separate explicit approval PR:")
    print("\n".join(" - " + p for p in blocked))
    sys.exit(1)
print("PASS no Valkyrie character art or approval-manifest files changed.")
