#!/bin/sh
# Download CAR files from Integration CI repository
# Uses Git sparse checkout to fetch only the /carbonapps folder
set -e

REPO_URL="$1"
REPO_REF="${2:-main}"

if [ -z "$REPO_URL" ]; then
    echo "ERROR: Repository URL is required"
    echo "Usage: $0 <repo-url> [ref]"
    exit 1
fi

echo "========================================="
echo "Downloading CARs from Integration CI"
echo "========================================="
echo "Repository: ${REPO_URL}"
echo "Reference:  ${REPO_REF}"
echo ""

# Clone with sparse checkout (only /carbonapps folder)
echo "→ Cloning repository (sparse checkout)..."
git clone --filter=blob:none --no-checkout --sparse "${REPO_URL}" repo-temp

cd repo-temp

# Configure sparse checkout for carbonapps folder only
echo "→ Configuring sparse checkout for /carbonapps..."
git sparse-checkout set carbonapps

# Checkout the specified ref
echo "→ Checking out ref: ${REPO_REF}..."
git checkout "${REPO_REF}"

# Create output directory
mkdir -p ../carbonapps

# Copy CAR files
echo "→ Copying CAR files..."
if [ -d "carbonapps" ]; then
    CAR_COUNT=$(find carbonapps -name "*.car" 2>/dev/null | wc -l)

    if [ "$CAR_COUNT" -gt 0 ]; then
        cp -v carbonapps/*.car ../carbonapps/ 2>/dev/null || true
        echo ""
        echo "✓ Downloaded ${CAR_COUNT} CAR file(s)"
    else
        echo "WARNING: No CAR files found in carbonapps/ folder"
        echo "Creating empty marker to indicate successful download"
        touch ../carbonapps/.no-cars
    fi
else
    echo "ERROR: carbonapps/ folder not found in repository"
    exit 1
fi

# Cleanup
cd ..
rm -rf repo-temp

echo ""
echo "Downloaded CAR files:"
ls -lh carbonapps/ 2>/dev/null || echo "  (none)"

echo ""
echo "✓ Download complete"
echo "========================================="
