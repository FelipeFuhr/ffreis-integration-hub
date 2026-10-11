# ffreis-integration-hub

<!-- ffreis-badges:start -->
[![CI](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/FelipeFuhr/ffreis-badges/main/badges/ffreis-integration-hub/ci.json)](https://github.com/FelipeFuhr/ffreis-integration-hub/actions) [![License](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/FelipeFuhr/ffreis-badges/main/badges/ffreis-integration-hub/license.json)](https://github.com/FelipeFuhr/ffreis-integration-hub/blob/main/LICENSE)
<!-- ffreis-badges:end -->

Cross-repository integration/parity runner for services that should stay behaviorally aligned.

## What this checks today

- Clones (or reuses local) repos defined in `config/repos.json`.
- Runs each repo parity targets:
  - `make grpc-check`
  - `make test-grpc-parity`
  - `make smoke-api-grpc`
- Enforces common target contract across repos:
  - `grpc-check`
  - `test-grpc-parity`
  - `smoke-api-grpc`

## Why this exists

This project is the shared integration layer. It can scale to more services and more contracts
without coupling any single service repository to the others.

## gRPC Reflection Policy

Across API repos in this workspace, gRPC server reflection is disabled by default.

Rationale:

- reduce unauthenticated surface area in runtime deployments,
- avoid extra runtime overhead in hot paths,
- keep service contracts explicit via `.proto` and dedicated parity/contract checks.

If a team needs reflection in a specific environment, it should be explicitly gated behind env
configuration and deployment auth controls, and remain off by default.

## Local usage

```bash
cd ffreis-integration-hub
make weekly-check-local
```

This uses `local_path` entries from `config/repos.json` and writes logs/summary to `artifacts/`.

Typing debt report across sibling Python repos:

```bash
cd ffreis-integration-hub
make typing-debt-report
```

Set `AGENT_REPO_DIR_NAME` to also scan the private RL-agent companion repo
(its name is not published here — pass the sibling directory name you
checked it out under) if you have it checked out locally; it is skipped by
default, same as any other sibling repo that isn't present on disk.

## Converter -> Serving parity bench

This integration scenario validates an end-to-end path:

1. Generate a sklearn model artifact.
2. Convert it through converter HTTP API.
3. Run Python serving API and Rust serving API in parallel with the generated ONNX.
4. Benchmark both APIs and assert output parity.

Run:

```bash
cd ffreis-integration-hub
make smoke-converter-serving-parity
```

Bench report is written to the shared model volume as `converter_serving_bench.json`.

Optional image override knobs:

```bash
make smoke-converter-serving-parity IMAGE_PROVIDER=ghcr.io IMAGE_PREFIX=ffreis IMAGE_TAG=integration
```

This resolves images like `ghcr.io/ffreis-converter:integration`,
`ghcr.io/ffreis-python-serving:integration`, and `ghcr.io/ffreis-rust-serving:integration`.

gRPC variant:

```bash
cd ffreis-integration-hub
make smoke-converter-serving-parity-grpc
```

gRPC bench report is written as `converter_serving_bench_grpc.json`.

## Stock Simulator + Dashboard Compatibility

This smoke check ensures `ffreis-stock-simulator` and
`ffreis-stock-simulator-dashboard-go` stay wire-compatible.

It boots both services via the dashboard repo compose stack, then verifies:

- dashboard health endpoint,
- dashboard state proxy (`/api/state`),
- reset proxy (`/api/reset`),
- step proxy (`/api/step`).

Run:

```bash
cd ffreis-integration-hub
make smoke-stock-sim-dashboard
```

## Stock Simulator + RL Agent Schema Compatibility

This check enforces that simulator live event payloads and replay schema remain
compatible with the private RL-agent companion repo's assumptions. That repo's
identity is intentionally not published in this public repo — see `AGENT_REPO`
below.

It validates:

- runtime simulator payload contract used by the agent (`/v1/observe`, `/v1/step_many`),
- feature-vector shape expected by the policy layer (11 features),
- replay schema fields in simulator `RecordedStep`,
- replay schema fields in agent `ReplayRow`.

Run (`AGENT_REPO` must point at a local checkout of the companion repo):

```bash
cd ffreis-integration-hub
AGENT_REPO=../<path-to-your-local-checkout> make smoke-stock-sim-agent-compat
```

## Unified Stock Stack (Compose)

A single compose scenario is available to stitch:

- simulator
- Go dashboard
- online RL agent
- offline experiment runner

Run (`AGENT_REPO` must point at a local checkout of the private RL-agent
companion repo; the Makefile resolves it to the absolute `AGENT_REPO_PATH`
the compose file consumes):

```bash
cd ffreis-integration-hub
AGENT_REPO=../<path-to-your-local-checkout> make stock-sim-full-stack
```

Compose file:

- `examples/docker-compose.stock-sim-dashboard-agent-experiments.yml`

## Python vs Rust ONNX Runner Comparison Harness

A starter harness is available at:

- `benchmarks/onnx-runner-comparison`

It supports two modes:

- `container`: compare both implementations running in containers
- `native`: compare both implementations as local processes

Run from integration hub:

```bash
cd ffreis-integration-hub
make compare-container
make compare-native
make compare-all
```

## CI usage

A weekly workflow is provided at:

- `.github/workflows/weekly-parity.yml`
- `.github/workflows/converter-serving-parity.yml`
- `.github/workflows/stock-sim-dashboard-compat.yml`
- `.github/workflows/stock-sim-agent-compat.yml`
- `.github/workflows/stock-sim-full-stack.yml`
- `.github/workflows/onnx-runner-comparison.yml` (includes standalone repo integration job)

Schedule:

- `weekly-parity.yml`: Monday 08:00 UTC
- `converter-serving-parity.yml`: Monday 08:30 UTC
- `stock-sim-dashboard-compat.yml`: Monday 09:00 UTC
- `stock-sim-agent-compat.yml`: Monday 09:20 UTC
- `stock-sim-full-stack.yml`: Monday 09:40 UTC

Optional secret for private repos:

- `INTEGRATION_REPO_TOKEN`

`stock-sim-agent-compat.yml` and `stock-sim-full-stack.yml` clone private
companion repos whose identity must not be hardcoded in this public repo.
Required repo variables (not secret — plain https clone URLs; set with
`gh variable set <name> --repo FelipeFuhr/ffreis-integration-hub --body
"https://github.com/<owner>/<repo>.git"`), both consumed via
`FLEET_READ_TOKEN_ORG` for auth:

- `COMPAT_REPO_URL` — the RL-agent companion repo (both workflows)
- `COMPAT_AGENT_RUNTIME_URL` — the agents-runtime companion repo (`stock-sim-full-stack.yml` only)

Both can be overridden per manual run via the matching `workflow_dispatch` input.

## Extending to more projects

1. Add a new repo in `config/repos.json`.
2. Add the repo checks (make commands or script commands).
3. Add/extend contracts in `contracts`.
4. Re-run `make weekly-check-local`.
