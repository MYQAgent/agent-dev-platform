# Makefile for a skill bundle.
# Run 'make help' for available targets.

SKILLS := skills/my-skill
REGISTRY ?= ghcr.io/your-org
IMAGE ?= $(REGISTRY)/my-skills
TAG ?= 0.1.0

.PHONY: help validate build push test

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*##' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "}; {printf "  %-14s %s\n", $$1, $$2}'

validate: ## Validate skill packaging
	@for s in $(SKILLS); do \
		[ -f "$$s/SKILL.md" ] || { echo "missing SKILL.md in $$s"; exit 1; }; \
	done
	@echo "validated"

build: ## Package skills into OCI (requires oras)
	oras push $(IMAGE):$(TAG) ./skills

push: build ## Push to registry

test: ## Run evals
	@echo "run evals per skill/evals/evals.json"
