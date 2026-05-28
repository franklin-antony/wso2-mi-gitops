# WSO2 Micro Integrator 4.3.x - Hardened Base Image
# Simplified version with minimal hardening

# Use the official WSO2 MI image directly as base
FROM wso2/wso2mi:4.3.0

# Switch to root to apply hardening
USER root

# Update packages and install required tools
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Remove unnecessary packages (if they exist)
RUN apt-get purge -y --auto-remove wget 2>/dev/null || true

# Set environment variables for JVM security
ENV JAVA_OPTS="-Djava.security.egd=file:/dev/./urandom \
-Djdk.tls.ephemeralDHKeySize=2048 \
-Djdk.tls.rejectClientInitiatedRenegotiation=true \
-Dhttps.protocols=TLSv1.2,TLSv1.3 \
-Djdk.tls.client.protocols=TLSv1.2,TLSv1.3"

# Metadata
LABEL org.opencontainers.image.source="https://github.com/franklin-antony/wso2-mi-gitops"
LABEL org.opencontainers.image.description="Hardened WSO2 Micro Integrator 4.3.x base image"
LABEL org.opencontainers.image.version="4.3.0-hardened"

# Switch back to wso2carbon user
USER wso2carbon
WORKDIR /home/wso2carbon

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:9201/healthz || exit 1

# Expose WSO2 MI ports
EXPOSE 8290 8253 9164 9201

# Use default CMD from base image
CMD ["/home/wso2carbon/wso2mi-4.3.0/bin/micro-integrator.sh"]
