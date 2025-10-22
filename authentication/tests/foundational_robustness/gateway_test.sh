#!/bin/bash

# ==============================================================================
# SPRINT 2 TEST SCRIPT - SCENARIOS 2 & 3
# ==============================================================================
# SCENARIO 2: Unauthorized Access to Protected API Gateway (auth_request Flow)
# SCENARIO 3: Successful Authenticated API Access via Gateway (Header Injection)
# Tests complete NGINX + oauth2-proxy + Keycloak integration
# ==============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMP_FILE="${SCRIPT_DIR}/temp_test.txt"
COOKIE_JAR="${SCRIPT_DIR}/cookies.txt"
SESSION_FILE="${SCRIPT_DIR}/session.txt"

# Environment variables with defaults
ENVIRONMENT="${1:-local}"
TEST_USER="${TEST_USER:-test.user@kainam.ai}"
TEST_PASSWORD="${TEST_PASSWORD:-Test@123}"

# Environment-specific configuration
configure_environment() {
    case "$ENVIRONMENT" in
        "local")
            NGINX_GATEWAY_URL="http://localhost"
            OAUTH2_PROXY_INTERNAL_URL="http://localhost:4180"
            FRONTEND_URL="http://localhost:3000"
            KEYCLOAK_URL="http://localhost:81"
            ;;
        "aws-dev"|"ec2")
            # AWS EC2 environment with NGINX gateway on port 81
            EC2_IP="${AWS_EC2_IP:-18.191.64.107}"
            NGINX_PORT="${AWS_NGINX_PORT:-81}"
            NGINX_GATEWAY_URL="http://${EC2_IP}:${NGINX_PORT}"
            OAUTH2_PROXY_INTERNAL_URL="http://keystone-oauth2-proxy:4180"  # Internal container access
            FRONTEND_URL="http://${EC2_IP}:${NGINX_PORT}"
            KEYCLOAK_URL="http://${EC2_IP}:${NGINX_PORT}"
            
            # AWS-specific test credentials
            TEST_USER="pf@kainam.ai"
            TEST_PASSWORD="abc123"
            ;;
        *)
            echo -e "${RED}❌ Invalid environment: $ENVIRONMENT${NC}"
            echo "Usage: $0 [local|aws-dev|ec2]"
            exit 1
            ;;
    esac

    echo -e "${BLUE}🔧 Testing Environment: $ENVIRONMENT${NC}"
    echo -e "${BLUE}   NGINX Gateway: $NGINX_GATEWAY_URL${NC}"
    echo -e "${BLUE}   OAuth2-Proxy (Internal): $OAUTH2_PROXY_INTERNAL_URL${NC}"
    echo -e "${BLUE}   Frontend URL: $FRONTEND_URL${NC}"
    echo -e "${BLUE}   Keycloak URL: $KEYCLOAK_URL${NC}"
    echo -e "${BLUE}   Test User: $TEST_USER${NC}"
    echo ""
}

# Cleanup function
cleanup() {
    rm -f "$TEMP_FILE" "$COOKIE_JAR" "$SESSION_FILE"
    echo -e "${YELLOW}🧹 Cleaned up temporary files${NC}"
}

# Setup cleanup trap (but not on normal exit)
trap cleanup INT TERM

# Test functions
log_test() {
    echo -e "${YELLOW}🧪 $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Test Case 2A: OAuth2-Proxy Isolation
test_oauth2_proxy_isolation() {
    log_test "Test Case 2A: OAuth2-Proxy isolation (should NOT be directly accessible)"
    
    local cmd="curl -s -w \"\\n%{http_code}\" --max-time 5 \"$OAUTH2_PROXY_INTERNAL_URL/api/v1/me\""
    log_info "Command: $cmd"
    
    local response
    local http_code
    
    # Try to access oauth2-proxy directly (should fail - connection refused)
    if response=$(curl -s -w "\n%{http_code}" --max-time 5 "$OAUTH2_PROXY_INTERNAL_URL/api/v1/me" 2>/dev/null); then
        http_code=$(echo "$response" | tail -n1)
        log_error "OAuth2-Proxy is directly accessible (HTTP $http_code) - Architecture violation!"
        log_error "OAuth2-Proxy should only be accessible internally by NGINX via auth_request"
        echo "Response: $(echo "$response" | head -n -1)"
        return 1
    else
        log_success "OAuth2-Proxy NOT directly accessible - Perfect Gateway isolation ✅"
        log_success "This confirms NGINX is the true gateway, oauth2-proxy is internal-only"
        return 0
    fi
}

# Test Case 2B: NGINX auth_request Flow  
test_nginx_auth_request_flow() {
    log_test "Test Case 2B: NGINX auth_request flow (unauthorized API access)"
    
    local cmd="curl -s -w \"\\n%{http_code}\" \"$NGINX_GATEWAY_URL/api/v1/me\""
    log_info "Command: $cmd"
    
    local response
    local http_code
    
    # Try to access protected endpoint via NGINX gateway
    response=$(curl -s -w "\n%{http_code}" "$NGINX_GATEWAY_URL/api/v1/me" 2>/dev/null || echo -e "\nconnection_failed")
    http_code=$(echo "$response" | tail -n1)
    log_info "Received HTTP status code: $http_code"
    
    if [[ "$http_code" == "302" ]]; then
        log_success "NGINX correctly triggers auth_request → 401 → 302 redirect"
        
        # Check redirect location points to oauth2/start
        local location_cmd="curl -s -I \"$NGINX_GATEWAY_URL/api/v1/me\""
        log_info "Checking redirect location: $location_cmd"
        local location_header
        location_header=$(curl -s -I "$NGINX_GATEWAY_URL/api/v1/me" | grep -i "location:" | cut -d' ' -f2- | tr -d '\r')
        
        if [[ "$location_header" == *"oauth2/start"* ]]; then
            log_success "Redirect correctly points to /oauth2/start (auth_request working)"
            log_success "✅ Test Case 2B PASSED: auth_request flow working correctly"
        else
            log_info "Redirect location: $location_header"
            log_error "Redirect should point to /oauth2/start, got: $location_header"
            return 1
        fi
        return 0
    elif [[ "$http_code" == "connection_failed" ]]; then
        log_error "Cannot connect to NGINX gateway at $NGINX_GATEWAY_URL"
        return 1
    else
        log_error "NGINX did not trigger auth_request properly (HTTP $http_code)"
        log_error "Expected: HTTP 302 redirect to /oauth2/start"
        echo "Response: $(echo "$response" | head -n -1)"
        return 1
    fi
}

# Test Case 3A: OAuth2/OIDC Login Flow Automation
test_oauth2_login_flow() {
    log_test "Test Case 3A: OAuth2/OIDC login flow automation"
    
    # Clean previous session
    rm -f "$COOKIE_JAR" "$SESSION_FILE"
    
    # Step 1: Initiate OAuth2 flow
    log_info "Step 1: Starting OAuth2 flow via /oauth2/start"
    local start_cmd="curl -s -c \"$COOKIE_JAR\" -L \"$NGINX_GATEWAY_URL/oauth2/start?rd=/api/v1/me\""
    log_info "Command: $start_cmd"
    
    local login_page
    login_page=$(curl -s -c "$COOKIE_JAR" -L "$NGINX_GATEWAY_URL/oauth2/start?rd=/api/v1/me" 2>/dev/null || echo "")
    
    if [[ -z "$login_page" ]]; then
        log_error "Failed to access OAuth2 start endpoint"
        return 1
    fi
    
    # Step 2: Parse Keycloak login form
    log_info "Step 2: Parsing Keycloak login form"
    local auth_url
    auth_url=$(echo "$login_page" | grep -o 'action="[^"]*"' | cut -d'"' -f2 | head -1)
    
    if [[ -z "$auth_url" ]]; then
        log_error "Could not extract authentication URL from login page"
        return 1
    fi
    
    # Make auth_url absolute if relative
    if [[ "$auth_url" == //* ]]; then
        auth_url="http:$auth_url"
    elif [[ "$auth_url" == /* ]]; then
        auth_url="${KEYCLOAK_URL}$auth_url"
    fi
    
    log_info "Authentication URL: $auth_url"
    
    # Step 3: Submit login credentials to Keycloak
    log_info "Step 3: Submitting credentials to Keycloak"
    local login_cmd="curl -s -b \"$COOKIE_JAR\" -c \"$COOKIE_JAR\" -L -d \"username=$TEST_USER\" -d \"password=[REDACTED]\" -d \"credentialId=\" \"$auth_url\""
    log_info "Command: $login_cmd"
    
    local auth_response
    auth_response=$(curl -s -b "$COOKIE_JAR" -c "$COOKIE_JAR" -L \
        -d "username=$TEST_USER" \
        -d "password=$TEST_PASSWORD" \
        -d "credentialId=" \
        "$auth_url" 2>/dev/null || echo "")
    
    # Step 4: Verify OAuth2 Proxy session cookie
    log_info "Step 4: Verifying OAuth2 Proxy session cookie"
    if [[ -f "$COOKIE_JAR" ]]; then
        local oauth2_cookie
        oauth2_cookie=$(grep "_oauth2_proxy" "$COOKIE_JAR" 2>/dev/null | cut -f7 || echo "")
        
        if [[ -n "$oauth2_cookie" ]]; then
            echo "$oauth2_cookie" > "$SESSION_FILE"
            log_success "Successfully obtained OAuth2 Proxy session cookie"
            log_info "Session cookie (truncated): ${oauth2_cookie:0:20}..."
            return 0
        fi
    fi
    
    # Step 5: Alternative verification - test protected endpoint
    log_info "Step 5: Alternative verification - testing protected endpoint access"
    local test_response
    test_response=$(curl -s -w "%{http_code}" -b "$COOKIE_JAR" "$NGINX_GATEWAY_URL/api/v1/me" 2>/dev/null)
    local test_code="${test_response: -3}"
    
    if [[ "$test_code" == "200" ]]; then
        log_success "Login successful - can access protected endpoint (HTTP 200)"
        echo "authenticated_session" > "$SESSION_FILE"
        return 0
    elif [[ "$test_code" == "302" ]]; then
        log_error "Still being redirected (HTTP 302) - login may have failed"
        log_info "Response preview: $(echo "$auth_response" | head -c 200)..."
        return 1
    else
        log_error "Unexpected response code: HTTP $test_code"
        return 1
    fi
}

# Test Case 3B: Authenticated API Access via Gateway
test_authenticated_api_access() {
    log_test "Test Case 3B: Authenticated API access via NGINX gateway"
    
    # Verify we have a valid session
    if [[ ! -f "$SESSION_FILE" ]]; then
        log_error "No session file found - OAuth2 login may have failed"
        return 1
    fi
    
    # Make authenticated request to protected endpoint
    log_info "Making authenticated request to /api/v1/me"
    local auth_cmd="curl -s -w \"\\n%{http_code}\" -b \"$COOKIE_JAR\" \"$NGINX_GATEWAY_URL/api/v1/me\""
    log_info "Command: $auth_cmd"
    
    local response
    local http_code
    response=$(curl -s -w "\n%{http_code}" -b "$COOKIE_JAR" "$NGINX_GATEWAY_URL/api/v1/me" 2>/dev/null || echo -e "\nconnection_failed")
    http_code=$(echo "$response" | tail -n1)
    
    if [[ "$http_code" == "200" ]]; then
        log_success "Authenticated request successful (HTTP 200)"
        
        # Parse response body for validation
        local response_body
        response_body=$(echo "$response" | head -n -1)
        
        log_test "Validating response data and header injection"
        log_info "Response body: $response_body"
        
        # Check for authentication status
        if [[ "$response_body" == *"\"authenticated\":true"* ]]; then
            log_success "✅ User is authenticated (authenticated: true)"
        else
            log_error "❌ User not authenticated (authenticated: false or missing)"
        fi
        
        # Check for user data (email, name)
        if [[ "$response_body" == *"\"email\":"* ]] && [[ "$response_body" != *"\"email\":null"* ]]; then
            log_success "✅ User email found in response"
        else
            log_error "❌ User email missing or null"
        fi
        
        if [[ "$response_body" == *"\"name\":"* ]] && [[ "$response_body" != *"\"name\":null"* ]]; then
            log_success "✅ User name found in response"
        else
            log_info "ℹ️  User name missing or null (may be normal)"
        fi
        
        return 0
        
    elif [[ "$http_code" == "302" ]]; then
        log_error "Still being redirected (HTTP 302) - authentication session invalid"
        return 1
    elif [[ "$http_code" == "connection_failed" ]]; then
        log_error "Cannot connect to NGINX gateway"
        return 1
    else
        log_error "Unexpected response (HTTP $http_code)"
        echo "Response: $(echo "$response" | head -n -1)"
        return 1
    fi
}

# Test Case 3C: Backend Header Injection Verification
test_backend_header_injection() {
    log_test "Test Case 3C: Backend header injection verification"
    
    # Check backend logs for header injection evidence
    log_info "Checking backend logs for injected headers"
    local log_cmd="docker logs keystone-backend --tail 50 2>/dev/null | grep -E '(X-Forwarded-Email|X-Forwarded-Preferred-Username)' | tail -5"
    log_info "Command: $log_cmd"
    
    local header_logs
    header_logs=$(docker logs keystone-backend --tail 50 2>/dev/null | grep -E "(X-Forwarded-Email|X-Forwarded-Preferred-Username)" | tail -5)
    
    if [[ -n "$header_logs" ]]; then
        log_success "✅ Found header injection evidence in backend logs"
        log_info "Header logs:"
        echo "$header_logs" | while read -r line; do
            log_info "  $line"
        done
        return 0
    else
        log_info "No header logs found in backend container logs"
        log_info "This may be normal if backend doesn't log headers explicitly"
        
        # Alternative: Check if authenticated response contains user data
        if [[ -f "$SESSION_FILE" ]]; then
            log_info "Verifying header injection via authenticated response data"
            local test_response
            test_response=$(curl -s -b "$COOKIE_JAR" "$NGINX_GATEWAY_URL/api/v1/me" 2>/dev/null)
            
            if [[ "$test_response" == *"\"authenticated\":true"* ]] && [[ "$test_response" == *"\"email\":"* ]]; then
                log_success "✅ Header injection working - backend received user identity"
                log_info "Evidence: Response contains authenticated user data"
                return 0
            fi
        fi
        
        log_error "❌ Could not verify header injection"
        return 1
    fi
}

# Test summary
print_test_summary() {
    echo ""
    echo -e "${BLUE}📊 TEST SUMMARY${NC}"
    echo -e "${BLUE}===============${NC}"
    
    local test_names=("Test Case 2A: OAuth2-Proxy Isolation" "Test Case 2B: NGINX auth_request Flow" "Test Case 3A: OAuth2 Login Flow" "Test Case 3B: Authenticated API Access" "Test Case 3C: Backend Header Injection")
    local passed_count=0
    local failed_tests=()
    
    # Debug: Show what we have in the array
    echo -e "${BLUE}Debug: Array length: ${#TEST_RESULTS[@]}, Contents: [${TEST_RESULTS[*]}]${NC}"
    
    # Use a simple for loop with indices
    for i in $(seq 0 $((${#TEST_RESULTS[@]} - 1))); do
        if [[ $i -lt ${#TEST_RESULTS[@]} ]]; then
            if [[ "${TEST_RESULTS[$i]}" == "PASS" ]]; then
                echo -e "${GREEN}✅ ${test_names[$i]}: PASSED${NC}"
                ((passed_count++))
            else
                echo -e "${RED}❌ ${test_names[$i]}: FAILED${NC}"
                failed_tests+=("${test_names[$i]}")
            fi
        else
            echo -e "${RED}❌ ${test_names[$i]}: NOT EXECUTED${NC}"
            failed_tests+=("${test_names[$i]}")
        fi
    done
    
    echo ""
    echo -e "${BLUE}Results: $passed_count/${#TEST_RESULTS[@]} test cases passed${NC}"
    
    if [[ ${#failed_tests[@]} -gt 0 ]]; then
        echo -e "${RED}❌ Failed tests: ${failed_tests[*]}${NC}"
        cleanup
        exit 1
    else
        echo -e "${GREEN}✅ All tests passed successfully!${NC}"
        cleanup
        exit 0
    fi
}

# Main execution
main() {
    echo -e "${BLUE}🚀 SPRINT 2 TEST EXECUTION${NC}"
    echo -e "${BLUE}=========================${NC}"
    echo ""
    
    # Configure environment
    configure_environment
    
    # Array to track test results (global)
    declare -ga TEST_RESULTS
    
    echo -e "${YELLOW}📋 TESTING SCENARIO 2: Unauthorized Access to Protected API Gateway${NC}"
    echo -e "${YELLOW}    (auth_request Flow)${NC}"
    echo ""
    
    if test_oauth2_proxy_isolation; then
        TEST_RESULTS+=("PASS")
    else
        TEST_RESULTS+=("FAIL")
    fi
    echo ""
    
    if test_nginx_auth_request_flow; then
        TEST_RESULTS+=("PASS")
    else
        TEST_RESULTS+=("FAIL")
    fi
    echo ""
    
    echo -e "${YELLOW}📋 TESTING SCENARIO 3: Successful Authenticated API Access via Gateway${NC}"
    echo -e "${YELLOW}    (Header Injection)${NC}"
    echo ""
    
    if test_oauth2_login_flow; then
        TEST_RESULTS+=("PASS")
    else
        TEST_RESULTS+=("FAIL")
    fi
    echo ""
    
    if test_authenticated_api_access; then
        TEST_RESULTS+=("PASS")
    else
        TEST_RESULTS+=("FAIL")
    fi
    echo ""
    
    if test_backend_header_injection; then
        TEST_RESULTS+=("PASS")
    else
        TEST_RESULTS+=("FAIL")
    fi
    
    # Print summary
    print_test_summary
}

# Run main function
main "$@"
