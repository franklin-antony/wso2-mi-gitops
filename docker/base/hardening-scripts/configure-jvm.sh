#!/bin/bash
# JVM security configuration for WSO2 MI
set -e

echo "========================================="
echo "Configuring JVM Security Options"
echo "========================================="

MI_HOME="/home/wso2carbon/wso2mi-4.3.0"
MI_SCRIPT="${MI_HOME}/bin/micro-integrator.sh"

if [ ! -f "$MI_SCRIPT" ]; then
    echo "ERROR: MI startup script not found at $MI_SCRIPT"
    exit 1
fi

echo "→ Adding security-hardened JVM options..."

# Create a wrapper script with JVM options
cat > "${MI_HOME}/bin/jvm-security-options.sh" << 'EOF'
#!/bin/bash
# Security-hardened JVM options
export JAVA_OPTS="$JAVA_OPTS -Djava.security.egd=file:/dev/./urandom"
export JAVA_OPTS="$JAVA_OPTS -Djdk.tls.ephemeralDHKeySize=2048"
export JAVA_OPTS="$JAVA_OPTS -Djdk.tls.rejectClientInitiatedRenegotiation=true"
export JAVA_OPTS="$JAVA_OPTS -Dhttps.protocols=TLSv1.2,TLSv1.3"
export JAVA_OPTS="$JAVA_OPTS -Djdk.tls.client.protocols=TLSv1.2,TLSv1.3"
EOF

# Make it executable
chmod +x "${MI_HOME}/bin/jvm-security-options.sh"

# Source this file in the main startup script by prepending it
# Backup original script first
cp "$MI_SCRIPT" "${MI_SCRIPT}.bak"

# Add source command at the beginning of the script (after shebang)
sed -i '2i\
# Source security JVM options\
if [ -f "$(dirname "$0")/jvm-security-options.sh" ]; then\
    . "$(dirname "$0")/jvm-security-options.sh"\
fi' "$MI_SCRIPT"

echo "→ JVM security options configured:"
echo "  ✓ Fast entropy source (non-blocking random)"
echo "  ✓ Strong DH key size (2048 bits)"
echo "  ✓ Reject client-initiated TLS renegotiation"
echo "  ✓ TLS 1.2 and 1.3 only"

echo "✓ JVM hardening complete"
echo "========================================="
