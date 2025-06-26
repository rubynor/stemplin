# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

**Setup:**
```bash
bundle install
rails assets:precompile
rails db:create
rails db:migrate
yarn install
rails db:fixtures:load  # Populate with test data
```

**Running the application:**
```bash
bin/dev  # Starts Rails server, JS/CSS watchers, and Sidekiq via Foreman
```

**Prerequisites:** Redis must be running (`redis-server --daemonize yes`)

**Testing:**
```bash
bin/rake test     # Run all tests
bin/rubocop       # Run linter
bin/rubocop -a    # Auto-fix linting issues
```

## Architecture Overview

**Tech Stack:** Ruby on Rails 7.1, PostgreSQL, Hotwire (Turbo + Stimulus), Tailwind CSS, Phlex components, Sidekiq with Redis

**Multi-tenant Architecture:** Organization-based data isolation with role-based access control (admin, member, spectator)

**Core Models:**
- Organizations → Clients → Projects → AssignedTasks
- Users ↔ AccessInfo ↔ Organizations (many-to-many with roles)
- TimeRegs (time entries) linked to users, projects, and tasks
- ProjectAccess for granular project-level permissions

## Critical Authorization Rules

This application uses ActionPolicy with strict data isolation requirements:

1. **ALWAYS use `authorized_scope`** when querying databases to prevent data leakage
2. **Use `authorize!` in EVERY controller action** and create policies for every action
3. **Multi-tenant scoping is mandatory** - all queries must respect organization boundaries

Example:
```ruby
def index
  authorize!
  @clients = authorized_scope(Client, type: :relation).all
end

def show
  @client = authorized_scope(Client, type: :relation).find(params[:id])
  authorize! @client
end
```

## Key Components

**Frontend:** 
- Phlex components in `/app/components/` with RubyUI component library
- Stimulus controllers in `/app/javascript/controllers/`
- Tailwind CSS with custom configuration

**Background Jobs:** Sidekiq with Redis (required for Hotwire functionality)

**Invitation System:** devise_invitable for user invitations with external project access

## Current Context

**Active Branch:** `feature/invite-to-project/external-user-invitation`
**Purpose:** Extending project access for external user invitations
**Main Branch:** `main`
