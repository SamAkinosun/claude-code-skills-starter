"""Smoke tests for .claude/hooks/block-secrets.sh.

Run from the repo root:

    python3 tests/test_block_secrets.py

Exits 0 on success, 1 on any failure.
"""

from __future__ import annotations

import json
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path

HOOK = Path(__file__).resolve().parent.parent / ".claude" / "hooks" / "block-secrets.sh"


@dataclass
class Case:
    name: str
    payload: dict
    expected_exit: int


CASES = [
    Case(
        name="clean python content is allowed",
        payload={
            "tool_name": "Write",
            "tool_input": {"file_path": "/tmp/x.py", "content": "print(1 + 1)\n"},
        },
        expected_exit=0,
    ),
    Case(
        name="github personal access token is blocked",
        payload={
            "tool_name": "Write",
            "tool_input": {
                "file_path": "/tmp/cfg.py",
                "content": 'TOKEN = "ghp_abcdefghijklmnopqrstuvwxyz0123456789"\n',
            },
        },
        expected_exit=2,
    ),
    Case(
        name="aws access key id is blocked on Edit",
        payload={
            "tool_name": "Edit",
            "tool_input": {
                "file_path": "/tmp/cfg.py",
                "old_string": "AWS_KEY = ''",
                "new_string": 'AWS_KEY = "AKIAIOSFODNN7EXAMPLE"',
            },
        },
        expected_exit=2,
    ),
    Case(
        name="private key block is blocked",
        payload={
            "tool_name": "Write",
            "tool_input": {
                "file_path": "/tmp/k.pem",
                "content": "-----BEGIN RSA PRIVATE KEY-----\nMIIE...\n-----END RSA PRIVATE KEY-----\n",
            },
        },
        expected_exit=2,
    ),
    Case(
        name="dotenv example file is allowed even with token-shaped value",
        payload={
            "tool_name": "Write",
            "tool_input": {
                "file_path": "/tmp/.env.example",
                "content": "GITHUB_TOKEN=ghp_abcdefghijklmnopqrstuvwxyz0123456789\n",
            },
        },
        expected_exit=0,
    ),
    Case(
        name="non Write/Edit tool calls are ignored",
        payload={
            "tool_name": "Bash",
            "tool_input": {"command": "ls"},
        },
        expected_exit=0,
    ),
    Case(
        name="slack token is blocked",
        payload={
            "tool_name": "Write",
            "tool_input": {
                "file_path": "/tmp/x.py",
                "content": 'TOK = "xoxb-1234567890-abcdefghijkl"',
            },
        },
        expected_exit=2,
    ),
]


def run() -> int:
    if not HOOK.exists():
        print(f"hook not found: {HOOK}", file=sys.stderr)
        return 1

    failed = 0
    for case in CASES:
        result = subprocess.run(
            [str(HOOK)],
            input=json.dumps(case.payload),
            capture_output=True,
            text=True,
        )
        ok = result.returncode == case.expected_exit
        status = "ok  " if ok else "FAIL"
        print(f"{status} {case.name}")
        if not ok:
            failed += 1
            print(f"     expected exit {case.expected_exit}, got {result.returncode}")
            if result.stderr:
                print(f"     stderr: {result.stderr.strip()}")

    print()
    print(f"{len(CASES) - failed}/{len(CASES)} passed")
    return 0 if failed == 0 else 1


if __name__ == "__main__":
    sys.exit(run())
