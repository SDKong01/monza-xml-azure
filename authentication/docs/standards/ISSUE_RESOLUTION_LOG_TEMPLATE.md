# ISSUE LOG: [Issue Number]: [Issue Title]

- **Date Opened:** YYYY-MM-DD
- **Owner:** [Agent Role or Orchestrator]
- **Status:** [Open | In Progress | Resolved | Closed]
- **Severity:** [Critical | High | Medium | Low]

---

## 1. Problem Understanding
*This section clearly defines the problem, its scope, and the desired outcome. It is the foundation for all subsequent analysis.*

- **What is the problem?**
  - *A clear, concise description of the observed behavior.*
- **When does it happen?**
  - *The specific triggers, times, or conditions under which the problem occurs.*
- **Where does it happen?**
  - *The specific environment (e.g., local, dev, prod), service, or code module.*
- **What is the impact?**
  - *The consequences of the problem (e.g., blocker for development, user-facing error).*
- **Root Cause Analysis (5 Whys):**
  - *A step-by-step analysis to uncover the fundamental cause.*
- **Key Assumptions Questioned:**
  - *A list of initial assumptions that were challenged and verified.*
- **Desired Outcome:**
  - *What does a "fixed" state look like?*

---

## 2. Problem Breakdown
*This section breaks the complex issue into smaller, manageable sub-problems.*

- **Sub-problem 1:** [Description of the first component of the problem.]
- **Sub-problem 2:** [Description of the second component of the problem.]
- **System Interactions:** [Analysis of how different parts of the system might be interacting to cause this issue.]

---

## 3. Solution Exploration
*A brainstorming phase to generate potential solutions without initial judgment.*

- **Option A:** [Description of a potential solution.]
  - **Pros:** [Advantages of this approach.]
  - **Cons:** [Disadvantages or risks of this approach.]
- **Option B:** [Description of another potential solution.]
  - **Pros:** [...]
  - **Cons:** [...]

---

## 4. Implementation and Testing
*A log of the iterative, scientific process of testing hypotheses and implementing fixes. Each iteration is a single experiment.*

### Iteration 1: [Title of the Experiment, e.g., "Increase Fargate CPU Allocation"]
- **Action:** [The specific change that was made or command that was run.]
- **Rationale:** [The hypothesis being tested. Why was this action taken?]
- **Result:** [The observed outcome. Did it work? Did the error change? Be specific.]
- **Notes:** [Any additional observations or learnings from this iteration.]

### Iteration 2: [Title of the Next Experiment]
- **Action:** [...]
- **Rationale:** [...]
- **Result:** [...]
- **Notes:** [...]

---

## 5. Final Solution & Review
*This section documents the final, successful solution and captures the key learnings.*

- **Final Solution Implemented:**
  - *A clear description of the changes that ultimately resolved the issue.*
- **Key Takeaways:**
  - *What was learned about the system or our processes from this issue?*
- **Preventative Actions:**
  - *What can be done to prevent this class of problem from happening again? (e.g., "Add new linter rule," "Update Runbook for deployments," "Add specific health check").*