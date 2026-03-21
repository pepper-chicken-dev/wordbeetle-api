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
- When beginning work, always pull the latest main branch and create a new branch with an appropriate name before making any changes.

## Communication

- Respond in Japanese
