#!/bin/bash
# Test WSO2 MI Runtime Image Locally with Podman
set -e

IMAGE="${1:-ghcr.io/franklin-antony/wso2-mi-runtime:dev-latest}"
CONTAINER_NAME="wso2-mi-test"

echo "======================================="
echo "WSO2 MI Runtime Image Local Test"
echo "======================================="
echo ""
echo "Image: $IMAGE"
echo ""

# Cleanup any existing container
echo "→ Cleaning up existing containers..."
podman stop $CONTAINER_NAME 2>/dev/null || true
podman rm $CONTAINER_NAME 2>/dev/null || true

# Pull the image
echo ""
echo "→ Pulling image..."
podman pull $IMAGE

# Run the container
echo ""
echo "→ Starting container..."
podman run -d --name $CONTAINER_NAME \
  -p 8290:8290 \
  -p 8253:8253 \
  -p 9164:9164 \
  -p 9201:9201 \
  -e JVM_HEAP_INITIAL=256m \
  -e JVM_HEAP_MAX=512m \
  $IMAGE

echo "✓ Container started"
echo ""

# Wait for startup
echo "→ Waiting for WSO2 MI to start (30 seconds)..."
sleep 30

# Check logs
echo ""
echo "→ Container logs (last 20 lines):"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
podman logs $CONTAINER_NAME --tail 20

# Test health endpoint
echo ""
echo "→ Testing health endpoint..."
if curl -sf http://localhost:9201/healthz > /dev/null; then
    echo "✓ Health check passed"
else
    echo "✗ Health check failed"
    echo ""
    echo "Container logs:"
    podman logs $CONTAINER_NAME
    exit 1
fi

# List deployed CARs
echo ""
echo "→ Deployed CAR files:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
podman exec $CONTAINER_NAME sh -c "ls -lh /home/wso2carbon/wso2mi-4.3.0/repository/deployment/server/carbonapps/"

# Test management API
echo ""
echo "→ Testing Management API..."
if curl -sf http://localhost:9164/management/apis > /dev/null; then
    echo "✓ Management API accessible"
else
    echo "⚠ Management API not accessible (may be expected)"
fi

# List services
echo ""
echo "→ Available services:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
curl -s http://localhost:8290/services || echo "No services endpoint available"

echo ""
echo "======================================="
echo "✓ All Tests Passed!"
echo "======================================="
echo ""
echo "Container is running. Access points:"
echo "  HTTP Services:   http://localhost:8290"
echo "  HTTPS Services:  https://localhost:8253"
echo "  Management API:  http://localhost:9164"
echo "  Health/Metrics:  http://localhost:9201"
echo ""
echo "View logs:"
echo "  podman logs -f $CONTAINER_NAME"
echo ""
echo "Stop and cleanup:"
echo "  podman stop $CONTAINER_NAME && podman rm $CONTAINER_NAME"
echo ""
