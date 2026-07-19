#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

ENVIRONMENT="${1:-}"
NAMESPACE="${2:-rtcdp}"
CHART="${3:-ingestion}"

if [[ -z "$ENVIRONMENT" ]]; then
    echo "Usage: $0 <environment> [namespace] [chart]"
    echo "  environment: dev, staging, prod"
    echo "  namespace: Kubernetes namespace (default: rtcdp)"
    echo "  chart: Helm chart name (default: ingestion)"
    exit 1
fi

if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    echo "Error: Invalid environment. Must be dev, staging, or prod."
    exit 1
fi

echo "=== RTCDP Healthcare Kubernetes Deployment ==="
echo "Environment: ${ENVIRONMENT}"
echo "Namespace: ${NAMESPACE}"
echo "Chart: ${CHART}"
echo ""

CHART_PATH="${PROJECT_ROOT}/deploy/kubernetes/charts/${CHART}"
VALUES_PATH="${PROJECT_ROOT}/deploy/kubernetes/values/${ENVIRONMENT}.yaml"

if [[ ! -d "$CHART_PATH" ]]; then
    echo "Error: Chart not found at ${CHART_PATH}"
    exit 1
fi

if [[ ! -f "$VALUES_PATH" ]]; then
    echo "Error: Values file not found at ${VALUES_PATH}"
    exit 1
fi

echo "Creating namespace if not exists..."
kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

echo "Upgrading/Installing Helm release..."
helm upgrade --install "${CHART}" "${CHART_PATH}" \
    --namespace "${NAMESPACE}" \
    --values "${VALUES_PATH}" \
    --wait \
    --timeout 5m

echo ""
echo "Verifying deployment..."
kubectl rollout status "deployment/${CHART}" -n "${NAMESPACE}" --timeout=120s

echo ""
echo "Pod status:"
kubectl get pods -n "${NAMESPACE}" -l "app=${CHART}"

echo ""
echo "=== Kubernetes deployment complete ==="
