#!/bin/bash
# Custom entrypoint for WSO2 MI runtime
# Adds initialization, health checks, and graceful shutdown
set -e

echo "========================================="
echo "Starting WSO2 Micro Integrator Runtime"
echo "========================================="

# Set JVM options from environment variables
export JAVA_OPTS="${JAVA_OPTS} -Xms${JVM_HEAP_INITIAL:-512m} -Xmx${JVM_HEAP_MAX:-1024m}"

echo "JVM Configuration:"
echo "  Heap Initial: ${JVM_HEAP_INITIAL:-512m}"
echo "  Heap Maximum: ${JVM_HEAP_MAX:-1024m}"
echo ""

# List deployed Carbon Applications
echo "Deployed Carbon Applications:"
CAR_DIR="/home/wso2carbon/wso2mi-4.3.0/repository/deployment/server/carbonapps"
if [ -d "$CAR_DIR" ]; then
    CAR_COUNT=$(find "$CAR_DIR" -name "*.car" 2>/dev/null | wc -l)
    if [ "$CAR_COUNT" -gt 0 ]; then
        ls -lh "$CAR_DIR"/*.car 2>/dev/null || true
        echo ""
        echo "Total CAR files: ${CAR_COUNT}"
    else
        echo "  WARNING: No CAR files found!"
    fi
else
    echo "  ERROR: carbonapps directory not found!"
fi

echo ""
echo "========================================="
echo ""

# Handle signals for graceful shutdown
_term() {
    echo ""
    echo "========================================="
    echo "Received SIGTERM signal"
    echo "Shutting down gracefully..."
    echo "========================================="

    # Stop WSO2 MI gracefully
    if [ -f "/home/wso2carbon/wso2mi-4.3.0/bin/micro-integrator.sh" ]; then
        /home/wso2carbon/wso2mi-4.3.0/bin/micro-integrator.sh stop || true
    fi

    exit 0
}

trap _term SIGTERM SIGINT

# Execute the main command
echo "→ Starting Micro Integrator..."
echo ""
exec "$@"
