# WSO2 Micro Integrator Runtime Image
# Multi-stage build: Downloads CARs from Integration CI repo and builds runtime image

# Global ARGs for stage 2 base image (must be before any FROM that uses them)
ARG BASE_IMAGE_TAG=4.3.0-hardened-latest
ARG REPOSITORY_OWNER=franklin-antony

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
# Use ARGs declared at the top of Dockerfile
FROM ghcr.io/${REPOSITORY_OWNER}/wso2-mi-base:${BASE_IMAGE_TAG}

# Re-declare ARGs after FROM so they're available in this build stage
ARG BASE_IMAGE_TAG
ARG REPOSITORY_OWNER

# Metadata
LABEL org.opencontainers.image.source="https://github.com/franklin-antony/wso2-mi-gitops"
LABEL org.opencontainers.image.description="WSO2 Micro Integrator runtime with deployed integrations"
LABEL org.opencontainers.image.version="runtime"

# Switch to root for file operations
USER root

# Copy custom entrypoint first
COPY --chown=wso2carbon:wso2 entrypoint.sh /usr/local/bin/custom-entrypoint.sh
RUN chmod +x /usr/local/bin/custom-entrypoint.sh

# Copy entire carbonapps directory (includes README.txt if no CARs)
# This approach handles empty directories gracefully
COPY --from=downloader --chown=wso2carbon:wso2 /workspace/carbonapps/ /home/wso2carbon/wso2mi-4.3.0/repository/deployment/server/carbonapps/

# Set proper permissions
RUN chown -R wso2carbon:wso2 /home/wso2carbon/wso2mi-4.3.0/repository/deployment/server/carbonapps/ && \
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
