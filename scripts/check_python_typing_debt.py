#!/usr/bin/env python3
"""Report (and optionally gate) Python typing debt across sibling repos.

Debt signals:
- explicit `Any`
- explicit `object` annotations
"""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
from pathlib import Path

DEFAULT_REPOS = [
    "ffreis-agent-runtime",
    "ffreis-stock-simulator",
    "ffreis-python-onnx-model-serving",
    "ffreis-python-onnx-model-converter",
    "ffreis-runner-comparison",
    "ffreis-integration-hub",
]

# The RL-agent companion repo is private; its name must not be hardcoded as
# a default in this public repo. Set AGENT_REPO_DIR_NAME to the sibling
# directory name (e.g. a local checkout named "rl-agent-companion") to
# include it in the scan; otherwise it is skipped, same as any other sibling
# repo that isn't checked out locally.
_agent_repo_dir_name = os.getenv("AGENT_REPO_DIR_NAME", "").strip()
if _agent_repo_dir_name:
    DEFAULT_REPOS.append(_agent_repo_dir_name)

EXCLUDE_GLOBS = [
    "src/*grpc*/*",
    "src/*_grpc/*",
    "src/*pb2*.py",
    "**/__pycache__/**",
]

PATTERN = re.compile(r"\bAny\b|\bobject\b")


def _count_debt(repo_dir: Path) -> int:
    cmd = ["rg", "-n", PATTERN.pattern, str(repo_dir), "-g", "*.py"]
    for glob in EXCLUDE_GLOBS:
        cmd.extend(["-g", f"!{glob}"])
    proc = subprocess.run(cmd, capture_output=True, text=True, check=False)
    if proc.returncode == 1:
        return 0
    if proc.returncode != 0:
        raise RuntimeError(proc.stderr.strip() or f"rg failed for {repo_dir}")
    return len([line for line in proc.stdout.splitlines() if line.strip()])


def main() -> int:
    parser = argparse.ArgumentParser(description="Check Python typing debt across repos")
    parser.add_argument(
        "--max-total", type=int, default=None, help="Fail if total debt exceeds this"
    )
    parser.add_argument("--json-out", default=None, help="Optional JSON report output path")
    args = parser.parse_args()

    root = Path(__file__).resolve().parents[2]
    counts: dict[str, int] = {}
    for repo in DEFAULT_REPOS:
        repo_dir = root / repo
        if not repo_dir.exists():
            continue
        counts[repo] = _count_debt(repo_dir)

    total = sum(counts.values())
    report = {"counts": counts, "total": total}

    print(json.dumps(report, indent=2))

    if args.json_out:
        out = Path(args.json_out)
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(json.dumps(report, indent=2), encoding="utf-8")

    if args.max_total is not None and total > args.max_total:
        print(f"typing debt check failed: total={total} > max_total={args.max_total}")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
