.DEFAULT_GOAL := help
SHELL := /usr/bin/env bash

IMAGE_PROVIDER ?= localhost
IMAGE_PREFIX ?= ffreis
IMAGE_TAG ?= integration
IMAGE_ROOT := $(if $(IMAGE_PROVIDER),$(IMAGE_PROVIDER)/,)$(IMAGE_PREFIX)
BENCH_DIR ?= benchmarks/onnx-runner-comparison

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
	-IMAGE_ROOT="$(IMAGE_ROOT)" IMAGE_TAG="$(IMAGE_TAG)" ./scripts/compose.sh -f examples/docker-compose.converter-serving-parity.yml down --remove-orphans
	IMAGE_ROOT="$(IMAGE_ROOT)" IMAGE_TAG="$(IMAGE_TAG)" ./scripts/compose.sh -f examples/docker-compose.converter-serving-parity.yml up --build --abort-on-container-exit --exit-code-from bench

.PHONY: smoke-converter-serving-parity-grpc
smoke-converter-serving-parity-grpc: ## Convert via converter gRPC, then benchmark Python vs Rust serving gRPC parity
	-IMAGE_ROOT="$(IMAGE_ROOT)" IMAGE_TAG="$(IMAGE_TAG)" ./scripts/compose.sh -f examples/docker-compose.converter-serving-parity-grpc.yml down --remove-orphans
	IMAGE_ROOT="$(IMAGE_ROOT)" IMAGE_TAG="$(IMAGE_TAG)" ./scripts/compose.sh -f examples/docker-compose.converter-serving-parity-grpc.yml up --build --abort-on-container-exit --exit-code-from bench-grpc

.PHONY: compare-container
compare-container: ## Run ONNX runner comparison harness in container mode
	cd $(BENCH_DIR) && $(MAKE) compare-container

.PHONY: compare-native
compare-native: ## Run ONNX runner comparison harness in native process mode
	cd $(BENCH_DIR) && $(MAKE) compare-native

.PHONY: compare-native-triple
compare-native-triple: ## Run native 3-way ONNX runner comparison (python onnx/sklearn + rust onnx)
	cd $(BENCH_DIR) && $(MAKE) compare-native-triple

.PHONY: compare-native-raw-all
compare-native-raw-all: ## Run native 5-way comparison (python onnx/sklearn/pytorch/tensorflow + rust onnx)
	cd $(BENCH_DIR) && $(MAKE) compare-native-raw-all

.PHONY: compare-all
compare-all: ## Run both container and native ONNX runner comparison modes
	cd $(BENCH_DIR) && $(MAKE) compare-container && $(MAKE) compare-native
