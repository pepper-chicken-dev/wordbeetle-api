---
name: git-commit
description: Git commit rules and conventions. Follow these when creating any git commit or planning commit strategy.
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git diff:*), AskUserQuestion
---

## Commit Message Rules

- Write in English
- Use the Conventional Commits format: `<type>: <description>`
  - Types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`
- Keep the subject line under 72 characters
- Do NOT include `Co-Authored-By` or any AI attribution

## Commit Grouping Guidelines

When multiple files are changed, group them into logical commits:

- Group files that serve the same purpose
- If there is only one file changed or all changes are clearly related, use a single commit

## Commit Workflow

When invoked directly, execute the following workflow.

### Context

- Current git status: !`git status`
- Current git diff (uncommitted changes): !`git diff HEAD`
- Current branch: !`git branch --show-current`

### Pre-check

- If there are no uncommitted changes, inform the user and stop. Do NOT proceed.
- Show the current branch name to the user and use AskUserQuestion to confirm:
  - "Continue on this branch"
  - "Stop" (user will switch branches manually)

### 1. Analyze changes and propose commit groups

Examine the diff and group changes into logical commits following the Commit Grouping Guidelines above.

Present your proposed groupings to the user as a numbered list showing files and commit message per group. Then use AskUserQuestion to confirm:

- "Proceed as proposed"
- "Combine into one commit"
- "Let me regroup" (user describes preferred grouping via Other)

If the user selects "Let me regroup", revise the groupings based on their input and re-confirm.

### 2. Commit

For each commit group (in the confirmed order):

- Stage only the files in that group with `git add`
- Create a commit following the Commit Message Rules above
