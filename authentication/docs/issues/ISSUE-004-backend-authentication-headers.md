# ISSUE LOG: 004: Backend 500 Error - Missing Authentication Headers

- **Date Opened:** August 2025
- **Owner:** Backend Engineer
- **Status:** Resolved
- **Severity:** High

---

## 1. Problem Understanding
- **What is the problem?**
  - The backend API returns a 500 Internal Server Error for all requests to protected endpoints, even after a user has successfully authenticated via the gateway.
- **What is the impact?**
  - Authenticated users cannot access any data or functionality from the API.
- **Root Cause Analysis (5 Whys):**
  - 1. Why the 500 error? -> The backend code was throwing an exception due to null values for user information.
  - 2. Why were the values null? -> The expected authentication headers were not present in the request.
  - 3. Why were the headers not present? -> The backend was coded to look for the wrong header names (e.g., `X-User-Email`).
  - 4. Why was it looking for the wrong names? -> An assumption was made about what headers `oauth2-proxy` would send, without verifying its default behavior.
- **Desired Outcome:**
  - The backend correctly parses user identity information from the headers provided by `oauth2-proxy` and successfully authorizes the request.

---

## 4. Implementation and Testing
### Iteration 1: Debug and Identify Actual Headers
- **Action:** Added logging to the backend API to print all incoming request headers.
- **Rationale:** To stop assuming and see what headers `oauth2-proxy` actually sends by default.
- **Result:** The logs revealed the correct headers were `X-Forwarded-Email`, `X-Forwarded-User`, etc.

### Iteration 2: Update Backend Header Mapping
- **Action:** Modified the FastAPI endpoint dependencies to read the correct `X-Forwarded-*` headers.
- **Rationale:** To align the backend's expectation with the proxy's actual behavior.
- **Result:** SUCCESS. The backend correctly parsed the user's identity, and the API calls succeeded.

---

## 5. Final Solution & Review
- **Final Solution Implemented:**
  - The backend application code was updated to read the default `X-Forwarded-*` headers sent by `oauth2-proxy` instead of custom `X-User-*` headers.
- **Key Takeaways:**
  - Always verify the default behavior of a proxy or middleware before implementing custom logic.
  - Systematic debugging (like logging all headers) is the fastest way to solve integration issues.