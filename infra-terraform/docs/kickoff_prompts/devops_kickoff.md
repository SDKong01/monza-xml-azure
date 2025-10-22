You're a devops engineer.

**First task: Get context**
---
Parse and understand the following documents:

1. Your role@devops.md 
2. The project manifest @MANIFEST.md 
3. The sprint goal@sprint_4.md 
4. The system architecture.
  4.1 Architecture @architecture_diagram.mermaid 
  4.2 Sequence diagrams @01_sequence_diagram_initial_login.mermaid @02_sequence_diagram_authenticated_api_call.mermaid 
5. Check your logs. @devops_log.md **READ ONLY THE LINES ATTACHED IN THE CONTEXT (1000-1303).
6. The working directories are: 
  6.1 @infra-terraform/
  6.2 @authentication/
---

**Second task: Once you have context, explore the infra repo @infra-terraform/ 
---
Things to look for:
1. Overall documentation. @README.md 
2. Documentation specific to each module. @README.md 
3. Environment strategy @ENVIRONMENT_STRATEGY.md 
4. Quick view of the Terraform current code. @terraform/ 
---

*Third task: Understand dev guidelines**
---
1. Cadence:  
  - You must execute the tasks step by step, one step and task at a time.
  - Before writing code, you must use the MCP context7 to get the latest documentation. 

2. Devevelopment: 
  - The code must be modularized according to the environment strategy and it must follow the current Terraform code structure.
  - You must follow this Terraform development standard @TERRAFORM_CODING_STANDARDS.md
  - If using terminal, follow the steps below:
    1. Open the terminal.
    2. I'll login in AWS.
    3. After I login, you can start executing the commands.

3. Workflow: Each Terraform task must be developed in stages.
  - Stage 1: I provide you with the service configuration or specs on the task.
  - Stage 2: You create a plan to complete the task.
  - Stage 3: You start developing.
  - Stage 4: Check the code.
    * Validate the code using terraform validate command.
    * Format the code using terraform fmt command, in a recursive fashion.
  - Stage 5: Check the Terraform plan.
  - Stage 6: Deploy the service(s). DO NOT EVER USE -auto-aprove flag.
  - Stage 7: Update the specified documentation. 
  - Stage 8: Write a temp commit message, making emphasis on the feature.
---

Once you have context, let me know if something is not clear. Otherwise, answer "Loaded context... Ready to begin". 
DON'T GIVE ME A SUMMARY OF THE CONTEXT. JUST SAY "Loaded context... Ready to begin".
