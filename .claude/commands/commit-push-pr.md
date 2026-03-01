---
allowed-tools: Bash(git checkout:*), Bash(git add:*), Bash(git status:*), Bash(git push:*), Bash(git commit:*), Bash(gh pr create:*), Bash(git stash:*), Bash(git pull:*), Bash(git fetch:*)
description: Commit, push, and open a PR
---

## Context

- Current git status: !`git status`
- Current git diff (staged and unstaged changes): !`git diff HEAD`
- Current branch: !`git branch --show-current`

## Your task

Based on the above changes:

### Pre-check

- If there are no changes (working tree is clean and no staged changes), inform the user and stop. Do NOT proceed.

### 1. Branch handling

**If on main**, create a new branch from the latest main:

- Stash uncommitted changes if any (`git stash`), skip if working tree is clean
- Fetch and pull the latest main (`git fetch origin && git pull origin main`)
- Create and switch to a new branch (`git checkout -b <branch-name>`)
- Pop the stash if it was used (`git stash pop`)
- Branch name must follow: `feature/<topic>`, `fix/<topic>`, `refactor/<topic>`, `docs/<topic>`, or `chore/<topic>`
- Derive the branch name from the actual diff content

**If on a non-main branch**, validate the branch name against the diff content:

- If they appear unrelated, warn the user and ask whether to continue on the current branch or create a new one. Do NOT proceed without confirmation.
- When creating a new branch: stash changes → `git checkout main` → fetch/pull latest → `git checkout -b <new-branch>` → pop stash

### 2. Commit and push

- Stage the relevant changed files with `git add`
- Create a single commit with a clear message in English derived from the diff
- Push the branch to origin (`git push -u origin <branch-name>`)

### 3. Create pull request

- Write PR body to a temp file (e.g., `tmp/pr_body.md`)
- Create a pull request: `gh pr create -t "<title>" -F tmp/pr_body.md`
- Title and body must be in English
- Clean up the temp file after PR creation
