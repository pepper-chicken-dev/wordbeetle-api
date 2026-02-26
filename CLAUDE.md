# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Setup
bin/setup                    # Install gems, prepare database

# Development
bin/dev                      # Start development server

# Testing
bin/rails test               # Run all tests
bin/rails test test/models/user_test.rb  # Run a single test file

# Linting & Security
bin/rubocop                  # Lint Ruby code (Rails Omakase style)
bin/brakeman                 # Security vulnerability scan
bin/bundler-audit            # Dependency vulnerability audit

# Full CI pipeline
bin/ci                       # Setup, lint, audit, test, seed

# Database
bin/rails db:migrate         # Run pending migrations
bin/rails db:seed:replant    # Reset and re-seed data
```

## Architecture

WordBeetle API is a **Rails 8.1 API-only** (no views) application for a spaced-repetition vocabulary learning app. Deployed via Kamal with Docker.

### API Structure

All endpoints are namespaced under `/api/v1/`. The single auth endpoint is `POST /api/v1/auth/google` for Google OAuth ID token verification. Resources follow standard Rails REST conventions: `wordbooks`, `words`, `meanings`, `examples`, `settings`.

### Authentication Flow

- **Google OAuth**: Client sends a Google ID token; the server verifies it via `Google::Auth::IDTokens.verify_oidc` (see `app/controllers/concerns/google_authenticatable.rb`) using `GOOGLE_CLIENT_ID` from environment.
- **Guest users**: Users with `provider: "guest"` must have `guest_expires_at` set (enforced at both model validation and DB check constraint level).
- Users are identified by `(provider, provider_uid)` — unique at DB level. Email has a separate unique index but can be nil.

### Data Model

- `User` → has_many `Wordbook` → has_many `Word` → has_many `Meaning`, has_many `Example`
- `User` → has_one `Setting` (stores SRS interval days: hard/uncertain/easy)
- Words have a `status` field (`learning`/`learned`) and `next_review_date` for spaced repetition scheduling.

### Key Conventions

- **Three databases**: primary (app data), cache (Solid Cache), queue (Solid Queue) — all PostgreSQL.
- Migrations use timestamped filenames. Recent migrations added DB-level constraints for user provider integrity.
- `docs/requirements.md` contains prioritized (P0/P1/P2) feature requirements across 8 development phases — consult it before adding features.
