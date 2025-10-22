#!/bin/bash
# 0_test_initial_setup.sh
# Verification script for WBS KEY-2: Create Initial Docker Compose File
# Tests that all required containers are running without errors

echo "=== Keystone RBAC - Initial Setup Verification ==="
echo "WBS: [KEY-2] Create Initial Docker Compose File"
echo "Timestamp: $(date)"
echo ""

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null; then
    echo "❌ ERROR: docker-compose not found"
    exit 1
fi

echo "1. Checking container status..."
echo "Expected containers: db (postgres), keycloak, backend (placeholder), frontend (placeholder)"
echo ""

# Get container status
containers=$(docker-compose ps --format json 2>/dev/null)
if [ -z "$containers" ]; then
    echo "❌ ERROR: No containers found. Run 'docker-compose up -d' first."
    exit 1
fi

# Check each required service
required_services=("db" "keycloak" "backend" "frontend")
all_running=true

for service in "${required_services[@]}"; do
    status=$(docker-compose ps $service --format json 2>/dev/null | grep -o '"State":"[^"]*"' | cut -d'"' -f4)
    
    if [ "$status" = "running" ]; then
        echo "✅ $service: running"
    else
        echo "❌ $service: $status (expected: running)"
        all_running=false
    fi
done

echo ""
echo "2. Testing Keycloak accessibility..."
echo -n "Testing Keycloak (http://localhost:8080)... "

if curl -f -s -m 10 "http://localhost:8080" > /dev/null 2>&1; then
    echo "✅ Accessible"
else
    echo "❌ Not accessible"
    all_running=false
fi

echo ""
echo "3. Verifying network connectivity..."
# Test that containers can communicate on keystone-net network
network_exists=$(docker network ls | grep -q "keystone-net" && echo "true" || echo "false")

if [ "$network_exists" = "true" ]; then
    echo "✅ keystone-net network exists"
else
    echo "❌ keystone-net network not found"
    all_running=false
fi

echo ""
echo "4. Checking for critical errors in logs..."
error_found=false

for service in "${required_services[@]}"; do
    # Get container name for the service
    container_name=$(docker-compose ps $service --format json 2>/dev/null | grep -o '"Name":"[^"]*"' | cut -d'"' -f4)
    
    if [ -n "$container_name" ]; then
        errors=$(docker logs "$container_name" --tail 10 2>&1 | grep -i "error\|fatal\|exception" | grep -v "INFO\|DEBUG" | wc -l)
        
        if [ $errors -gt 0 ]; then
            echo "⚠️  $service ($container_name) has $errors recent errors"
            error_found=true
        else
            echo "✅ $service - no critical errors"
        fi
    fi
done

echo ""
echo "=== SUMMARY ==="
if [ "$all_running" = true ] && [ "$error_found" = false ]; then
    echo "🎉 WBS KEY-2 COMPLETED SUCCESSFULLY!"
    echo "✅ All required containers are running"
    echo "✅ Keycloak is accessible"
    echo "✅ Network configuration is correct"
    echo "✅ No critical errors detected"
    echo ""
    echo "Next step: Proceed to WBS KEY-3 (Configure Minimal Keycloak Container)"
    exit 0
else
    echo "⚠️  Issues detected in initial setup:"
    if [ "$all_running" = false ]; then
        echo "   - Some containers are not running properly"
    fi
    if [ "$error_found" = true ]; then
        echo "   - Critical errors found in container logs"
    fi
    echo ""
    echo "Review the output above and fix issues before proceeding."
    exit 1
fi
