#!/bin/bash
# Trigger base image build workflow manually
set -e

echo "========================================="
echo "Trigger WSO2 MI Base Image Build"
echo "========================================="
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

echo "→ Triggering build-base-image workflow..."
gh workflow run build-base-image.yml

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
echo "Base image build completed"
echo ""
echo "To view the image:"
echo "  docker pull ghcr.io/\$(gh repo view --json owner -q .owner.login | tr '[:upper:]' '[:lower:]')/wso2-mi-base:4.3.0-hardened-latest"
echo ""
echo "========================================="
