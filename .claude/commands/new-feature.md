When this command is run it means we are developing a new feature. To safeguard the codebase, we will first plan the task, then we will TDD it.

- first ask a lot of questions to the user. gather a good understanding of the feature to be built. Make a todo list of questions and ask them one by one.
- then use the prd-agent to write out a PRD in the docs/features/<feature-name>/PRD.md folder. This is the time to ask clarifying questions. Think through all the edge cases.
- once this is done ask the user to review and approve the PRD
  - Then we will use the tdd-agent to TDD the feature
  - Then we will use the refactoring agent to clean up the code we wrote. 
  - then we will use the QA agent to check whether the tests match the PRD and whether they all pass. the qa-agent will also start a puppetteer session to click through the browser (localhost:4090) and it will write out a cypress test file that can be run against the dev server later.
