# Overview

WordBeetle API is the backend for a spaced-repetition vocabulary learning app.

## Tech Stack

- Ruby on Rails 8.1 (API-only mode)
- PostgreSQL
- Authentication: Google ID token verification (`googleauth` gem)
- Testing: RSpec, FactoryBot, shoulda-matchers

## Project Structure

- `app/controllers/api/v1/` — All API endpoints are namespaced under `Api::V1`

## Reference Documents

Read these as needed based on the task.

- `docs/requirements.md` — Feature requirements and priorities (P0/P1/P2). Currently working on P0 items.
- `docs/er_diagram.plantuml` — Database ER diagram

## Workflow

- Before starting implementation, enter plan mode to design the approach and align with the user.
  - The plan must include a commit strategy: define how to group changes into logical commits and a draft commit message for each.
- When beginning work, always pull the latest main branch and create a new branch with an appropriate name before making any changes.
- During implementation, commit incrementally according to the plan. Create each commit as soon as the corresponding unit of work is complete, rather than batching all commits at the end.

## Commit Messages

- Write in English
- Use the Conventional Commits format: `<type>: <description>`
  - Types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`
- Do NOT include `Co-Authored-By` or any AI attribution

## Communication

- Respond in Japanese
