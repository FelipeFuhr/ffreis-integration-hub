"""Readiness helpers."""

from __future__ import annotations

import time

import httpx


def wait_http_ok(url: str, timeout_s: float = 240.0) -> None:
    # Native mode starts the Rust service via `cargo run`, which builds AND
    # runs in one step — on a cold CI cache a from-scratch build of the
    # onnx-serving app easily exceeds 60s, which was long enough to fail
    # every native-mode CI run in this workflow's history (never observed
    # passing) even though the service eventually comes up healthy.
    deadline = time.time() + timeout_s
    last_error: Exception | None = None
    while time.time() < deadline:
        try:
            response = httpx.get(url, timeout=3.0)
            if response.status_code == 200:
                return
        except Exception as exc:  # noqa: BLE001
            last_error = exc
        time.sleep(0.5)
    raise RuntimeError(f"Timed out waiting for {url}: {last_error}")
