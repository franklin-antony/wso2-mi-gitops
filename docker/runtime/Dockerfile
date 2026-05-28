# WSO2 Micro Integrator Runtime Image
# Multi-stage build: Downloads CARs from Integration CI repo and builds runtime image

# Stage 1: Download CARs from Integration CI repository
FROM alpine:latest AS downloader

# Install required tools
RUN apk add --no-cache git curl

# Set working directory
WORKDIR /workspace

# Copy download script
COPY download-cars.sh .

# Build arguments for Integration CI repo
ARG INTEGRATION_REPO_URL
ARG INTEGRATION_REPO_REF=main

# Download CARs
RUN if [ -z "$INTEGRATION_REPO_URL" ]; then \
        echo "ERROR: INTEGRATION_REPO_URL build arg is required"; \
        echo "Build with: docker build --build-arg INTEGRATION_REPO_URL=<url> ."; \
        exit 1; \
    fi && \
    chmod +x download-cars.sh && \
    ./download-cars.sh "${INTEGRATION_REPO_URL}" "${INTEGRATION_REPO_REF}"

# Stage 2: Runtime image with CARs
ARG BASE_IMAGE_TAG=4.3.0-hardened-latest
ARG REPOSITORY_OWNER=franklin-antony
FROM ghcr.io/${REPOSITORY_OWNER}/wso2-mi-base:${BASE_IMAGE_TAG}

# Metadata
LABEL org.opencontainers.image.source="https://github.com/franklin-antony/wso2-mi-gitops"
LABEL org.opencontainers.image.description="WSO2 Micro Integrator runtime with deployed integrations"
LABEL org.opencontainers.image.version="runtime"

# Switch to root for file operations
USER root

# Copy custom entrypoint first
COPY --chown=wso2carbon:wso2 entrypoint.sh /usr/local/bin/custom-entrypoint.sh
RUN chmod +x /usr/local/bin/custom-entrypoint.sh

# Copy CARs using RUN with conditional logic (handles empty gracefully)
RUN --mount=type=bind,from=downloader,source=/workspace/carbonapps,target=/tmp/cars \
    mkdir -p /home/wso2carbon/wso2mi-4.3.0/repository/deployment/server/carbonapps/ && \
    if ls /tmp/cars/*.car 1> /dev/null 2>&1; then \
        cp /tmp/cars/*.car /home/wso2carbon/wso2mi-4.3.0/repository/deployment/server/carbonapps/ && \
        echo "Copied $(ls /tmp/cars/*.car | wc -l) CAR files"; \
    else \
        echo "No CAR files found - deploying empty runtime image"; \
        echo "No CARs deployed yet" > /home/wso2carbon/wso2mi-4.3.0/repository/deployment/server/carbonapps/README.txt; \
    fi && \
    chown -R wso2carbon:wso2 /home/wso2carbon/wso2mi-4.3.0/repository/deployment/server/carbonapps/ && \
    chmod -R 755 /home/wso2carbon/wso2mi-4.3.0/repository/deployment/server/carbonapps/

# Switch back to non-root user
USER wso2carbon

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:9201/healthz || exit 1

# Expose WSO2 MI ports
EXPOSE 8290 8253 9164 9201

# Use custom entrypoint
ENTRYPOINT ["/usr/local/bin/custom-entrypoint.sh"]

# Default command - starts WSO2 MI
CMD ["/home/wso2carbon/wso2mi-4.3.0/bin/micro-integrator.sh"]
