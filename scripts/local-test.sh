#!/bin/bash
# Local Docker build and test for runtime image
set -e

INTEGRATION_REPO="${1:-https://github.com/example/wso2-integrations}"
INTEGRATION_REF="${2:-main}"

echo "========================================="
echo "Local WSO2 MI Runtime Build & Test"
echo "========================================="
echo ""
echo "Configuration:"
echo "  Integration Repo: ${INTEGRATION_REPO}"
echo "  Integration Ref:  ${INTEGRATION_REF}"
echo ""

# Check Docker
if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker is not installed"
    exit 1
fi

# Get repository owner (lowercase)
REPO_OWNER=$(git config --get remote.origin.url | sed -n 's/.*github\.com[:/]\([^/]*\).*/\1/p' | tr '[:upper:]' '[:lower:]')

if [ -z "$REPO_OWNER" ]; then
    echo "WARNING: Could not detect repository owner, using 'local'"
    REPO_OWNER="local"
fi

echo "→ Building runtime image..."
docker build \
  --build-arg INTEGRATION_REPO_URL="${INTEGRATION_REPO}" \
  --build-arg INTEGRATION_REPO_REF="${INTEGRATION_REF}" \
  --build-arg BASE_IMAGE_TAG="4.3.0-hardened-latest" \
  --build-arg REPOSITORY_OWNER="${REPO_OWNER}" \
  -t wso2-mi-runtime:local \
  -f docker/runtime/Dockerfile \
  docker/runtime/

echo ""
echo "✓ Image built successfully"

echo ""
echo "→ Running smoke tests..."
chmod +x docker/runtime/smoke-test.sh
./docker/runtime/smoke-test.sh wso2-mi-runtime:local

echo ""
echo "========================================="
echo "✓ Local build and test completed"
echo "========================================="
echo ""
echo "Image: wso2-mi-runtime:local"
echo ""
echo "To run the image:"
echo "  docker run -p 8290:8290 -p 9201:9201 wso2-mi-runtime:local"
echo ""
echo "To test endpoints:"
echo "  curl http://localhost:9201/healthz"
echo "  curl http://localhost:8290/services"
echo ""
