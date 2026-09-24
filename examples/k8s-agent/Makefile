# Makefile for the k8s-agent example skill bundle.
# Run 'make help' for available targets.

SKILLS := skills/k8s-knowledge skills/k8s-troubleshoot skills/k8s-security
REGISTRY ?= ghcr.io/example
IMAGE ?= $(REGISTRY)/k8s-skills
TAG ?= 0.1.0

.PHONY: help validate build push test

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*##' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "}; {printf "  %-14s %s\n", $$1, $$2}'

validate: ## Validate skill packaging
	@for s in $(SKILLS); do \
		echo "validating $$s"; \
		[ -f "$$s/SKILL.md" ] || { echo "missing SKILL.md in $$s"; exit 1; }; \
	done
	@echo "all skills validated"

build: ## Package skills into an OCI artifact (requires oras)
	oras push $(IMAGE):$(TAG) ./skills

push: ## Push to registry (alias for build)
	$(MAKE) build

test: ## Run evals (placeholder; see docs/02-intermediate/05-testing.md)
	@echo "run evals via sub-agent per skill/evals/evals.json"
	@for s in $(SKILLS); do \
		echo "evals: $$s/evals/evals.json"; \
		[ -f "$$s/evals/evals.json" ] && echo "  found" || echo "  (none)"; \
	done
