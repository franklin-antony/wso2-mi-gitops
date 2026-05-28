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

# Backup original script
cp "$MI_SCRIPT" "${MI_SCRIPT}.bak"

# Add JVM security options before the startup command
# These options are inserted near the end of the script, before the actual Java invocation
sed -i '/# ---------- Handle the SSL Issue with proper JAVA_HOME/a \
\
# Security-hardened JVM options (added by hardening script)\
JAVA_OPTS="$JAVA_OPTS -Djava.security.egd=file:/dev/./urandom"\
JAVA_OPTS="$JAVA_OPTS -Djdk.tls.ephemeralDHKeySize=2048"\
JAVA_OPTS="$JAVA_OPTS -Djdk.tls.rejectClientInitiatedRenegotiation=true"\
JAVA_OPTS="$JAVA_OPTS -Dhttps.protocols=TLSv1.2,TLSv1.3"\
JAVA_OPTS="$JAVA_OPTS -Djdk.tls.client.protocols=TLSv1.2,TLSv1.3"\
\
export JAVA_OPTS' "$MI_SCRIPT"

echo "→ JVM security options configured:"
echo "  ✓ Fast entropy source (non-blocking random)"
echo "  ✓ Strong DH key size (2048 bits)"
echo "  ✓ Reject client-initiated TLS renegotiation"
echo "  ✓ TLS 1.2 and 1.3 only"

echo "✓ JVM hardening complete"
echo "========================================="
