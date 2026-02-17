.DEFAULT_GOAL := help
SHELL := /usr/bin/env bash

.PHONY: help
help:
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z_-]+:.*##/ {printf "\033[36m%-26s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: weekly-check
weekly-check: ## Clone/update configured repos and run all parity checks
	./scripts/weekly_check.py

.PHONY: weekly-check-local
weekly-check-local: ## Run checks against local sibling repos
	./scripts/weekly_check.py --use-local-repos

.PHONY: print-summary
print-summary: ## Print latest JSON summary
	@cat artifacts/summary.json

.PHONY: smoke-converter-serving-parity
smoke-converter-serving-parity: ## Convert via converter API, then benchmark Python vs Rust serving parity
	-./scripts/compose.sh -f examples/docker-compose.converter-serving-parity.yml down --remove-orphans
	./scripts/compose.sh -f examples/docker-compose.converter-serving-parity.yml up --build --abort-on-container-exit --exit-code-from bench

.PHONY: smoke-converter-serving-parity-grpc
smoke-converter-serving-parity-grpc: ## Convert via converter gRPC, then benchmark Python vs Rust serving gRPC parity
	-./scripts/compose.sh -f examples/docker-compose.converter-serving-parity-grpc.yml down --remove-orphans
	./scripts/compose.sh -f examples/docker-compose.converter-serving-parity-grpc.yml up --build --abort-on-container-exit --exit-code-from bench-grpc
