# Multi-stage Dockerfile for Keycloak Authentication Service

# Stage 1: Build Stage - Optimize Keycloak for PostgreSQL and production features
FROM quay.io/keycloak/keycloak:26.3.2 AS builder

# Set build-time environment variables for optimization
ENV KC_DB=postgres
ENV KC_HEALTH_ENABLED=true
ENV KC_METRICS_ENABLED=true
ENV KC_FEATURES=token-exchange,admin-fine-grained-authz

# Copy custom Kainam theme
COPY kainam-theme.jar /opt/keycloak/providers/kainam-theme.jar

# Build the optimized Keycloak image
# This pre-configures the database driver and enables specified features
RUN /opt/keycloak/bin/kc.sh build

# Stage 2: Runtime Stage - Lightweight production image
FROM quay.io/keycloak/keycloak:26.3.2 AS runtime

# Copy the optimized Keycloak build from the builder stage
COPY --from=builder /opt/keycloak/ /opt/keycloak/

# Create non-root user for security (if not already present)
USER keycloak

# Set working directory
WORKDIR /opt/keycloak

# Expose Keycloak port
EXPOSE 8080

# Health check endpoint - using wget since curl is not available in Keycloak container
HEALTHCHECK --interval=30s --timeout=10s --retries=5 --start-period=60s \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health/ready || exit 1

# Set default entrypoint and command
# Runtime configuration will be provided via environment variables
ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
CMD ["start", "--optimized"]
