### Standard Operating Procedure: The AAS Issue Resolution Process

This document outlines the standard procedure for using the **Issue Resolution Log** to systematically troubleshoot and resolve complex problems within the Agentic Agile Swarm (AAS) framework. This process ensures that issues are handled consistently, learnings are captured, and the framework's knowledge base grows over time.

#### When to Initiate This Process

This formal process should be triggered by the Orchestrator when a problem is identified that meets one or more of the following criteria:

* It is a **persistent blocker** to development progress.
* The root cause is **not immediately obvious** after initial debugging attempts.
* The issue has **significant architectural or security implications.**
* The resolution is likely to require **multiple, iterative steps** to solve.

#### The Step-by-Step Procedure

##### Step 1: Issue Declaration and Triage

1.  **Create the Log:** The **Orchestrator** initiates the process by creating a new `ISSUE_RESOLUTION_LOG.md` file in the `/docs/issues/` directory, following the standard naming convention (e.g., `ISSUE-003-database-connection-errors.md`).
2.  **Fill the Header:** The Orchestrator fills out the header section of the log:
    * `Date Opened`: Current date.
    * `Owner`: Assigns a primary **AI Agent Role** responsible for the investigation (e.g., `DevOps Engineer`).
    * `Status`: Set to `Open`.
    * `Severity`: Triage the issue as `Critical`, `High`, `Medium`, or `Low`.
3.  **Update the Manifest:** The Orchestrator adds a link to the new issue log in the `MANIFEST.md` to ensure project-wide visibility.

##### Step 2: Problem Understanding (Section 1)

1.  **Prompt the Owner:** The Orchestrator tasks the assigned **Owner Agent** with the first phase of the investigation.
    * **Example Prompt:** *"A critical issue has been logged at `/docs/issues/ISSUE-003.md`. Your task is to conduct a full investigation and complete Section 1: Problem Understanding. Use all available logs, metrics, and source code to be as detailed as possible."*
2.  **Agent Executes:** The agent analyzes the problem and populates all fields in Section 1 of the log.
3.  **Orchestrator Review:** The Orchestrator reviews the agent's analysis to ensure the problem is clearly and accurately defined before proceeding.

##### Step 3: Solution Exploration (Sections 2 & 3)

1.  **Prompt for Solutions:** Once the problem is understood, the Orchestrator tasks an appropriate agent (often the **Backend Architect** or the Owner) to break down the problem and brainstorm solutions.
    * **Example Prompt:** *"Based on the analysis in ISSUE-003, complete Sections 2 and 3. Break the problem down into its core components and propose at least two potential solutions with their pros and cons."*
2.  **Agent Executes:** The agent populates the "Problem Breakdown" and "Solution Exploration" sections of the log.

##### Step 4: Iterative Implementation and Testing (Section 4)

This is the core, scientific debugging loop. It is managed closely by the Orchestrator.

1.  **Select a Hypothesis:** The Orchestrator chooses one of the proposed solutions to test.
2.  **Prompt for a Single Iteration:** The Orchestrator tasks an engineering agent to perform a single, specific action.
    * **Example Prompt:** *"We will now test Option A from ISSUE-003. Your task is to perform the following action: \[Describe the specific action\]. Log your work as a new Iteration in Section 4 of the log file."*
3.  **Agent Executes and Logs:** The agent performs the action and meticulously fills out a new `Iteration` block in Section 4, detailing the **Action**, **Rationale**, **Result**, and any **Notes**.
4.  **Review and Repeat:** The Orchestrator reviews the result.
    * If the issue is resolved, proceed to Step 5.
    * If the issue is not resolved, the Orchestrator selects the next hypothesis to test and initiates a new iteration. This loop continues until a solution is found.

##### Step 5: Resolution and Knowledge Capture (Section 5)

1.  **Prompt for Final Review:** Once the issue is confirmed as resolved, the Orchestrator tasks the **Owner Agent** to complete the final section of the log.
    * **Example Prompt:** *"The issue in ISSUE-003 is now resolved. Complete Section 5: Final Solution & Review. Document the final fix, identify the key takeaways, and propose concrete preventative actions."*
2.  **Agent Executes:** The agent populates the final section, focusing on capturing knowledge.
3.  **Create New Tasks:** The "Preventative Actions" identified by the agent should be reviewed by the Orchestrator and, if approved, turned into new tasks in the main `tasks.yml` backlog.

##### Step 6: Closing the Loop

1.  **Update Status:** The Orchestrator updates the `Status` in the issue log's header to `Resolved` or `Closed`.
2.  **Update Manifest:** The Orchestrator updates the `MANIFEST.md` to reflect that the issue is no longer active. The framework has now successfully resolved a complex problem and integrated the learnings back into its workflow.