# ISSUE LOG: ISSUE-008: EC2 Frontend Port Configuration Mismatch

- **Date Opened:** 2025-08-29
- **Owner:** Backend Engineer  
- **Status:** Closed - RESOLVED
- **Severity:** High

---

## 1. Problem Understanding
*This section clearly defines the problem, its scope, and the desired outcome. It is the foundation for all subsequent analysis.*

- **What is the problem?**
  - EC2 Gateway deployment completely fails with 502 Bad Gateway errors when accessing frontend through NGINX
  - Frontend inaccessible via NGINX gateway (http://18.191.64.107:81/)
  - OAuth2 authentication flow broken due to frontend unavailability
  - Sprint 2 test suite fails on EC2 environment

- **When does it happen?**
  - Occurs immediately after EC2 deployment of gateway architecture
  - Happens when accessing frontend through NGINX gateway on port 81
  - Consistently reproducible on every EC2 access attempt

- **Where does it happen?**
  - Environment: EC2 production (docker-compose.yml with ec2.env)
  - Components: NGINX gateway → Frontend (Next.js) connection failure
  - Specific endpoint: GET / via NGINX gateway (http://18.191.64.107:81/)

- **What is the impact?**
  - Blocker for EC2 deployment and production readiness
  - Complete frontend inaccessibility through gateway architecture
  - Authentication flow cannot proceed (frontend required for login UI)
  - All protected API endpoints inaccessible due to auth dependency

- **Root Cause Analysis (5 Whys):**
  - **Why 1:** Why does NGINX return 502 Bad Gateway? → NGINX cannot connect to frontend upstream
  - **Why 2:** Why can't NGINX connect to frontend? → Connection refused on expected port
  - **Why 3:** Why is connection refused? → Next.js app not listening on expected port 3000
  - **Why 4:** Why isn't Next.js on port 3000? → EC2 Next.js configured to listen on port 3001
  - **Why 5:** Why port mismatch? → NGINX upstream configuration assumes local port strategy (3000) but EC2 uses different strategy (3001)

- **Key Assumptions Questioned:**
  - ✅ Verified: All containers running and healthy
  - ✅ Verified: AWS Secrets Manager environment variables correctly injected
  - ✅ Verified: Docker port mappings correct (3001:3000)
  - ❌ **FAILED**: NGINX upstream port assumption (expected 3000, actual 3001)
  - ✅ Verified: Backend accessible directly (http://18.191.64.107:8001)

- **Desired Outcome:**
  - Frontend accessible via NGINX gateway (HTTP 200 responses)
  - Complete OAuth2 authentication flow working end-to-end
  - Sprint 2 test suite passes on EC2 environment
  - Gateway architecture fully functional in production

---

## 2. Problem Breakdown
*This section breaks the complex issue into smaller, manageable sub-problems.*

- **Sub-problem 1: NGINX Upstream Configuration**
  - NGINX configured to connect to frontend on internal port 3000
  - Actual Next.js app listening on internal port 3001
  - Port strategy difference between local and EC2 environments

- **Sub-problem 2: Container Network Communication**
  - Docker networking functioning correctly (DNS resolution working)
  - Port mapping external:internal (3001:3000) vs internal service ports
  - NGINX uses internal Docker networking, not external port mappings

- **Sub-problem 3: Environment Configuration Consistency**
  - Local environment: Next.js on 3000, NGINX connects to 3000 ✅
  - EC2 environment: Next.js on 3001, NGINX connects to 3000 ❌
  - Configuration drift between environments

- **System Interactions:**
  - Browser → NGINX:81 → Frontend:3000 (expected) ❌ Connection refused
  - Browser → NGINX:81 → Frontend:3001 (actual) ✅ Working
  - Frontend container accessible directly on external port 3001 ❌ Also fails
  - Backend container accessible directly on external port 8001 ✅ Working

---

## 3. Solution Exploration
*A brainstorming phase to generate potential solutions without initial judgment.*

- **Option A: Fix NGINX Upstream Configuration**
  - Update nginx.conf to connect to keystone-frontend:3001 instead of :3000
  - **Pros:** Simple config change, maintains EC2 port strategy, quick fix
  - **Cons:** Creates configuration drift between local and EC2 NGINX configs

- **Option B: Standardize Next.js Port Across Environments**
  - Modify EC2 Next.js to listen on port 3000 like local environment
  - **Pros:** Consistent configuration across environments, no NGINX changes
  - **Cons:** Requires frontend container rebuild, changes established EC2 port strategy

- **Option C: Environment-Specific NGINX Configurations**
  - Create separate nginx-local.conf and nginx-ec2.conf files
  - **Pros:** Clean separation, environment-specific optimizations possible
  - **Cons:** Maintenance overhead, configuration duplication

---

## 4. Implementation and Testing
*A log of the iterative, scientific process of testing hypotheses and implementing fixes. Each iteration is a single experiment.*

### Iteration 1: Container Status and Health Verification
- **Action:** Check all container status with `docker-compose ps` and verify secret injection
- **Rationale:** Eliminate basic infrastructure issues before investigating specific component failures
- **Result:** SUCCESS - All containers running and healthy, AWS Secrets Manager correctly injecting credentials
- **Notes:** Issue not related to container startup or credential injection. Focus on service communication.

### Iteration 2: Service-by-Service Connectivity Testing
- **Action:** Test direct connectivity to backend (8001) and frontend (3001) external ports
- **Rationale:** Isolate whether issue is NGINX-specific or broader connectivity problem
- **Result:** MIXED - Backend accessible on :8001 ✅, Frontend inaccessible on :3001 ❌
- **Notes:** Backend working confirms network/security not the issue. Frontend problem confirmed.

### Iteration 3: NGINX Error Log Analysis
- **Action:** Examine NGINX logs for specific error messages and upstream connection attempts
- **Rationale:** Get detailed error information to identify exact failure point
- **Result:** ROOT CAUSE IDENTIFIED - NGINX logs show "connection refused" to upstream "http://172.18.0.6:3000/"
- **Notes:** NGINX successfully resolving frontend container IP but connection refused on port 3000.

### Iteration 4: Frontend Container Internal Process Investigation
- **Action:** Check processes inside frontend container and listening ports with `ps aux` and `netstat -tlnp`
- **Rationale:** Verify what port Next.js actually listening on inside container
- **Result:** CONFIRMED - Next.js listening on :::3001, NOT :::3000 as expected
- **Notes:** Evidence: `next dev -p 3001` command and netstat showing 3001. Port mismatch confirmed.

### Iteration 5: Fix NGINX Upstream Configuration
- **Action:** Update nginx.conf upstream frontend_service from `keystone-frontend:3000` to `keystone-frontend:3001`
- **Rationale:** Align NGINX configuration with actual Next.js listening port
- **Result:** SUCCESS - Frontend accessible via NGINX gateway with HTTP 200 OK responses
- **Notes:** Immediate resolution. Full HTML content served, Next.js headers present, gateway working.

---

## 5. Final Solution & Review
*This section documents the final, successful solution and captures the key learnings.*

- **Final Solution Implemented:**
  **Root Cause:** Port configuration mismatch between NGINX upstream configuration (expecting port 3000) and actual Next.js listening port (3001) in EC2 environment.

  **Solution Steps:**
  1. **Update NGINX Upstream Configuration:**
     - File: `authentication/nginx.conf`
     - Change: `upstream frontend_service { server keystone-frontend:3000; }` 
     - To: `upstream frontend_service { server keystone-frontend:3001; }`
  
  2. **Restart NGINX Service:**
     - Command: `docker-compose restart nginx`
     - Verify: `curl -v http://18.191.64.107:81/` returns HTTP 200 OK
  
  3. **Test Complete Gateway Flow:**
     - Frontend accessible via NGINX ✅
     - Ready for OAuth2 authentication testing ✅

  **Technical Details:**
  - Next.js startup command in EC2: `next dev -p 3001`
  - Docker port mapping: `3001:3000` (external:internal)
  - NGINX uses internal Docker networking, connects directly to container port
  - Local environment uses port 3000, EC2 environment uses port 3001

- **Key Takeaways:**
  1. **Environment Port Strategy Differences:** Local and EC2 environments use different internal port strategies that must be reflected in NGINX configuration
  2. **Docker Internal vs External Networking:** NGINX connects via internal Docker networking (container:port), not external port mappings
  3. **Container Process Inspection:** Use `docker exec` with `ps aux` and `netstat` to verify actual listening ports vs assumptions
  4. **Configuration Drift Prevention:** Port strategy differences between environments require careful configuration management
  5. **Systematic Debugging:** Container health → Service connectivity → Log analysis → Process inspection → Configuration fix

- **Preventative Actions:**
  1. **Environment Documentation:** Clearly document port strategies for each environment (local vs EC2 vs production)
  2. **Configuration Validation:** Add startup health checks that verify NGINX can connect to all upstream services
  3. **Automated Testing:** Include port connectivity tests in deployment scripts
  4. **Docker Compose Comments:** Add comments explaining port mapping strategies and internal vs external port usage
  5. **Environment Parity Checks:** Create scripts to validate consistent service communication across environments
  6. **NGINX Configuration Management:** Consider environment-specific NGINX configs (nginx-local.conf vs nginx-ec2.conf) for clarity

- **Configuration Management Impact:**
  - This issue highlights the need for better environment-specific configuration management
  - Consider Infrastructure as Code approaches for NGINX configuration
  - Document port strategy decisions and their cascading effects on dependent services
