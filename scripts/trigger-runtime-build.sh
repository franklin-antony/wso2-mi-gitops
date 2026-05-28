#!/bin/bash
# Trigger runtime image build workflow manually
set -e

INTEGRATION_REPO="${1:-https://github.com/example/wso2-integrations}"
INTEGRATION_REF="${2:-main}"
ENVIRONMENT="${3:-dev}"

echo "========================================="
echo "Trigger WSO2 MI Runtime Image Build"
echo "========================================="
echo ""
echo "Configuration:"
echo "  Integration Repo: ${INTEGRATION_REPO}"
echo "  Integration Ref:  ${INTEGRATION_REF}"
echo "  Environment:      ${ENVIRONMENT}"
echo ""

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "ERROR: GitHub CLI (gh) is not installed"
    echo "Install from: https://cli.github.com/"
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo "ERROR: Not authenticated with GitHub CLI"
    echo "Run: gh auth login"
    exit 1
fi

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    echo "ERROR: Invalid environment: ${ENVIRONMENT}"
    echo "Valid options: dev, staging, prod"
    exit 1
fi

echo "→ Triggering build-runtime-image workflow..."
gh workflow run build-runtime-image.yml \
  -f integration_repo_url="${INTEGRATION_REPO}" \
  -f integration_repo_ref="${INTEGRATION_REF}" \
  -f environment="${ENVIRONMENT}"

echo ""
echo "✓ Workflow triggered successfully"
echo ""
echo "→ Monitoring workflow run..."
echo "  (Press Ctrl+C to stop monitoring, build will continue)"
echo ""

# Wait a moment for the run to appear
sleep 3

# Watch the latest run
gh run watch --exit-status || true

echo ""
echo "========================================="
echo "Runtime image build completed"
echo ""
if [ "$ENVIRONMENT" == "prod" ]; then
    echo "⚠️  Production deployment requires manual approval:"
    echo "  1. Check the built image tag in the workflow summary"
    echo "  2. Update helm/wso2-mi/values-prod.yaml"
    echo "  3. Create a PR for review"
    echo "  4. After merge, ArgoCD will sync"
else
    echo "✓ Helm values updated automatically for ${ENVIRONMENT}"
    echo "✓ ArgoCD will auto-sync to ${ENVIRONMENT} environment"
fi
echo ""
echo "========================================="
