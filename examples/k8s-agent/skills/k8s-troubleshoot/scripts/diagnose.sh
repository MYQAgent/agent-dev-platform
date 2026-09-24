#!/usr/bin/env bash
# Diagnose a Kubernetes pod and emit structured JSON.
# Usage: diagnose.sh <pod> [-n <namespace>]
set -euo pipefail

POD="${1:?usage: diagnose.sh <pod> [-n <namespace>]}"
NS="default"
shift
while [[ $# -gt 0 ]]; do
  case "$1" in
    -n) NS="${2:?namespace required}"; shift 2 ;;
    *) shift ;;
  esac
done

status_json="$(kubectl get pod "$POD" -n "$NS" -o json 2>/dev/null || true)"
phase="$(echo "$status_json" | jq -r '.status.phase // "Unknown"')"
reason="$(echo "$status_json" | jq -r '.status.reason // ""')"
containers="$(echo "$status_json" | jq -r '[.status.containerStatuses[]? | {name: .name, ready: .ready, restartCount: .restartCount, state: (.state | keys[0])}]')"

events="$(kubectl get events -n "$NS" --field-selector involvedObject.name="$POD" -o json 2>/dev/null | jq -r '[.items[] | {type, reason, message}]')"

jq -n \
  --arg pod "$POD" \
  --arg ns "$NS" \
  --arg phase "$phase" \
  --arg reason "$reason" \
  --argjson containers "$containers" \
  --argjson events "$events" \
  '{pod: $pod, namespace: $ns, phase: $phase, reason: $reason, containers: $containers, events: $events}'
