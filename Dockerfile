####################################
# Stage 1: Builder - Install dependencies
####################################
FROM python:3.12-slim AS builder

# Set working directory
WORKDIR /app

# Set build-time environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Install build dependencies (needed for compiling Python packages)
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    g++ \
    && rm -rf /var/lib/apt/lists/*

# Copy only requirements to leverage Docker cache
COPY requirements.txt .

# Install dependencies to a specific directory
# This allows us to copy only the installed packages to the final image
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

####################################
# Stage 2: Runtime - Minimal final image
####################################
FROM python:3.12-slim AS runtime

# Set working directory
WORKDIR /app

# Copy installed packages from builder stage FIRST
# This is the magic: we don't copy gcc, build tools, etc.
COPY --from=builder /install /usr/local

# Set runtime environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    ENVIRONMENT=production \
    PYTHONPATH="/app"

# Copy only the application code (not build artifacts)
COPY . .

# Create non-root user for security
RUN useradd --create-home --shell /bin/bash --uid 1000 app \
    && chown -R app:app /app

# Switch to non-root user
USER app

# Expose port
EXPOSE 8000

# # Health check - use the simple /health endpoint
# HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
#     CMD python3 -c "import requests; requests.get('http://localhost:8000/health')" || exit 1

# Run the application with uvicorn via manage.py
CMD ["python3", "manage.py", "runserver"]
