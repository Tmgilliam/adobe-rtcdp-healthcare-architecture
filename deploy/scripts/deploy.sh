#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

ENVIRONMENT="${1:-}"
ACTION="${2:-apply}"

if [[ -z "$ENVIRONMENT" ]]; then
    echo "Usage: $0 <environment> [action]"
    echo "  environment: dev, staging, prod"
    echo "  action: plan, apply, destroy (default: apply)"
    exit 1
fi

if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    echo "Error: Invalid environment. Must be dev, staging, or prod."
    exit 1
fi

echo "=== RTCDP Healthcare Infrastructure Deployment ==="
echo "Environment: ${ENVIRONMENT}"
echo "Action: ${ACTION}"
echo ""

cd "${PROJECT_ROOT}/deploy/terraform"

echo "Initializing Terraform..."
terraform init \
    -backend-config="key=${ENVIRONMENT}.tfstate" \
    -reconfigure

echo "Validating configuration..."
terraform validate

case "$ACTION" in
    plan)
        echo "Planning changes..."
        terraform plan \
            -var-file="environments/${ENVIRONMENT}.tfvars" \
            -out="${ENVIRONMENT}.tfplan"
        ;;
    apply)
        echo "Planning changes..."
        terraform plan \
            -var-file="environments/${ENVIRONMENT}.tfvars" \
            -out="${ENVIRONMENT}.tfplan"
        
        echo ""
        read -p "Apply these changes? (yes/no): " confirm
        if [[ "$confirm" == "yes" ]]; then
            terraform apply "${ENVIRONMENT}.tfplan"
        else
            echo "Aborted."
            exit 0
        fi
        ;;
    destroy)
        echo "WARNING: This will destroy all resources in ${ENVIRONMENT}!"
        read -p "Type the environment name to confirm: " confirm
        if [[ "$confirm" == "$ENVIRONMENT" ]]; then
            terraform destroy \
                -var-file="environments/${ENVIRONMENT}.tfvars"
        else
            echo "Confirmation failed. Aborted."
            exit 1
        fi
        ;;
    *)
        echo "Error: Invalid action. Must be plan, apply, or destroy."
        exit 1
        ;;
esac

echo ""
echo "=== Deployment complete ==="
