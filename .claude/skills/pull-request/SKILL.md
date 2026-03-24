---
name: pull-request
description: PR creation rules and conventions. Follow these when creating a pull request.
allowed-tools: Bash(git push:*), Bash(git log:*), Bash(git branch:*), Bash(git status:*), Bash(git diff:*), Bash(gh pr create:*), AskUserQuestion
---

## PR Title Rules

- Write in English
- Use the Conventional Commits format: `<type>: <description>`
  - Types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`
- Keep the title under 72 characters

## PR Body Template

```
## Summary
- <bullet point describing the change>
```

- Write the summary in English
- Use concise bullet points (1-3 items)
- Focus on **what** changed and **why**, not implementation details

## PR Workflow

When invoked directly, execute the following workflow.

### Context

- Current branch: !`git branch --show-current`
- Commits on this branch (vs main): !`git log main..HEAD --oneline`

### Pre-check

- If the current branch is `main`, inform the user and stop. Do NOT proceed.
- If there are no commits ahead of main, inform the user and stop. Do NOT proceed.
- Show the branch name and commit list to the user and use AskUserQuestion to confirm:
  - "Create PR"
  - "Stop"

### 1. Push and create PR

- Push the branch to remote: `git push -u origin <branch>`
- Create the PR with `gh pr create` targeting `main`, using the title and body rules above
- Display the created PR URL to the user
