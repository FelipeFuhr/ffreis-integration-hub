# ffreis-integration-hub

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

## Local usage

```bash
cd ffreis-integration-hub
make weekly-check-local
```

This uses `local_path` entries from `config/repos.json` and writes logs/summary to `artifacts/`.

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

gRPC variant:

```bash
cd ffreis-integration-hub
make smoke-converter-serving-parity-grpc
```

gRPC bench report is written as `converter_serving_bench_grpc.json`.

## CI usage

A weekly workflow is provided at:

- `.github/workflows/weekly-parity.yml`

Schedule:

- Every Monday at 08:00 UTC.

Optional secret for private repos:

- `INTEGRATION_REPO_TOKEN`

## Extending to more projects

1. Add a new repo in `config/repos.json`.
2. Add the repo checks (make commands or script commands).
3. Add/extend contracts in `contracts`.
4. Re-run `make weekly-check-local`.
