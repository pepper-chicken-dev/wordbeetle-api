---
allowed-tools: Bash(git checkout:*), Bash(git add:*), Bash(git status:*), Bash(git commit:*), Bash(git stash:*), Bash(git pull:*), Bash(git fetch:*), Bash(git diff:*), AskUserQuestion
description: Analyze changes and create well-organized commits
---

## Context

- Current git status: !`git status`
- Current git diff (uncommitted changes): !`git diff HEAD`
- Current branch: !`git branch --show-current`

## Your task

Based on the above context:

### Pre-check

- If there are no uncommitted changes, inform the user and stop. Do NOT proceed.

### 1. Analyze changes and propose commit groups

Examine the diff and group changes into logical commits:

- Group files that serve the same purpose
- Each group needs: a list of files and a short commit message in English
- Order groups by dependency
- If there is only one file changed or all changes are clearly related, propose a single group

Present your proposed groupings to the user as a numbered list showing files and commit message per group. Then use AskUserQuestion to confirm:

- "Proceed as proposed"
- "Combine into one commit"
- "Let me regroup" (user describes preferred grouping via Other)

If the user selects "Let me regroup", revise the groupings based on their input and re-confirm.

### 2. Branch handling

Derive a branch name from the overall set of changes. The name must follow: `feature/<topic>`, `fix/<topic>`, `refactor/<topic>`, `docs/<topic>`, or `chore/<topic>`.

**Always** confirm the branch name with the user using AskUserQuestion:

- Show your proposed branch name
- "Use this name"
- "Suggest alternatives" (you propose 2-3 alternatives, then re-confirm)
- The user can also type a custom name via Other

**If on main:**

- Stash uncommitted changes if any (`git stash`), skip if working tree is clean
- Fetch and pull the latest main (`git fetch origin && git pull origin main`)
- Create and switch to the confirmed branch (`git checkout -b <branch-name>`)
- Pop the stash if it was used (`git stash pop`)

**If on a non-main branch:**

- If the confirmed name matches the current branch, stay on it
- Otherwise: stash changes → `git checkout main` → fetch/pull latest → `git checkout -b <new-branch>` → pop stash

### 3. Commit

For each commit group (in the confirmed order):

- Stage only the files in that group with `git add`
- Create a commit with the group's message
- Do NOT include `Co-Authored-By` or any AI attribution in commit messages
