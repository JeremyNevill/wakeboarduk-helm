#!/bin/bash

# Script to update GHCR login secrets across all namespaces
# Usage: ./update-ghcr-secrets.sh <github-token>

set -e

# Check if token is provided
if [ -z "$1" ]; then
    echo "Error: GitHub token not provided"
    echo "Usage: ./update-ghcr-secrets.sh <github-token>"
    echo ""
    echo "Example: ./update-ghcr-secrets.sh ghp_xxxxxxxxxxxx"
    exit 1
fi

TOKEN="$1"
DOCKER_SERVER="ghcr.io"
DOCKER_USERNAME="JeremyNevill"
DOCKER_EMAIL="jeremy@nevill.net"
SECRET_NAME="ghcr-login-secret"

# Define namespaces
NAMESPACES=("wuk-prod" "wuk-test" "wsf-prod" "wdc-prod")

echo "Updating GHCR login secrets in all namespaces..."
echo "================================================"
echo ""

for NAMESPACE in "${NAMESPACES[@]}"; do
    echo "Processing namespace: $NAMESPACE"

    # Check if namespace exists
    if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
        echo "  ⚠️  Namespace $NAMESPACE does not exist, skipping..."
        echo ""
        continue
    fi

    # Delete existing secret if it exists
    if kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" &> /dev/null; then
        echo "  🗑️  Deleting existing secret..."
        kubectl delete secret "$SECRET_NAME" -n "$NAMESPACE"
    fi

    # Create new secret
    echo "  ✅ Creating new secret..."
    kubectl create secret docker-registry "$SECRET_NAME" \
        --namespace="$NAMESPACE" \
        --docker-server="$DOCKER_SERVER" \
        --docker-username="$DOCKER_USERNAME" \
        --docker-password="$TOKEN" \
        --docker-email="$DOCKER_EMAIL"

    echo "  ✅ Secret updated successfully in $NAMESPACE"
    echo ""
done

echo "================================================"
echo "All secrets updated successfully!"
echo ""
echo "Updated namespaces:"
for NAMESPACE in "${NAMESPACES[@]}"; do
    if kubectl get namespace "$NAMESPACE" &> /dev/null; then
        echo "  ✅ $NAMESPACE"
    fi
done
