#!/bin/bash
# Validate Helm chart templates
set -e

echo "========================================="
echo "Helm Chart Validation"
echo "========================================="
echo ""

CHART_PATH="./helm/wso2-mi"

# Check if Helm is installed
if ! command -v helm &> /dev/null; then
    echo "ERROR: Helm is not installed"
    echo "Install from: https://helm.sh/docs/intro/install/"
    exit 1
fi

# Check if chart directory exists
if [ ! -d "$CHART_PATH" ]; then
    echo "ERROR: Helm chart not found at: $CHART_PATH"
    exit 1
fi

echo "→ Linting Helm chart..."
helm lint "$CHART_PATH"

echo ""
echo "→ Validating templates with dev values..."
helm template wso2-mi-dev "$CHART_PATH" \
  -f "$CHART_PATH/values-dev.yaml" \
  --debug \
  --dry-run > /dev/null

echo "✓ Dev values template renders successfully"

echo ""
echo "→ Validating templates with prod values..."
helm template wso2-mi-prod "$CHART_PATH" \
  -f "$CHART_PATH/values-prod.yaml" \
  --debug \
  --dry-run > /dev/null

echo "✓ Prod values template renders successfully"

echo ""
echo "========================================="
echo "✓ All Helm validation checks passed"
echo "========================================="
echo ""
echo "To install locally:"
echo "  helm install wso2-mi-dev $CHART_PATH \\"
echo "    -f $CHART_PATH/values-dev.yaml \\"
echo "    --namespace wso2-mi-dev \\"
echo "    --create-namespace"
echo ""
