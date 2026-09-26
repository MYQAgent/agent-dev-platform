#!/usr/bin/env bash
# Check current kubectl context and detect multi-cluster conflicts.
# Outputs structured JSON for agent consumption.
# Usage: check-context.sh
set -euo pipefail

CURRENT_CONTEXT=$(kubectl config current-context 2>/dev/null || echo "NONE")
ALL_CONTEXTS=$(kubectl config get-contexts -o name 2>/dev/null || echo "")
CONTEXT_COUNT=$(echo "$ALL_CONTEXTS" | wc -l)

CURRENT_CLUSTER=$(kubectl config view --minify -o jsonpath='{.clusters[0].name}' 2>/dev/null || echo "NONE")
CURRENT_NAMESPACE=$(kubectl config view --minify -o jsonpath='{.contexts[0].context.namespace}' 2>/dev/null || echo "default")

AVAILABLE=$(echo "$ALL_CONTEXTS" | jq -R -s -c 'split("\n") | map(select(length > 0))')

WARNING=""
if [ "$CONTEXT_COUNT" -gt 1 ]; then
  WARNING="你有 ${CONTEXT_COUNT} 个 context，当前指向 '${CURRENT_CONTEXT}'"
fi

if [ "$CURRENT_CONTEXT" = "NONE" ]; then
  WARNING="未检测到有效 context，请检查 KUBECONFIG 或 ~/.kube/config"
fi

jq -n \
  --arg currentContext "$CURRENT_CONTEXT" \
  --argjson availableContexts "$AVAILABLE" \
  --arg currentCluster "$CURRENT_CLUSTER" \
  --arg currentNamespace "$CURRENT_NAMESPACE" \
  --arg contextCount "$CONTEXT_COUNT" \
  --arg warning "$WARNING" \
  '{
    currentContext: $currentContext,
    availableContexts: $availableContexts,
    currentCluster: $currentCluster,
    currentNamespace: $currentNamespace,
    contextCount: ($contextCount | tonumber),
    warning: $warning
  }'