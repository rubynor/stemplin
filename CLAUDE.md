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

**Test Patterns:**
- Fixtures loaded with `fixtures :all`
- ActionPolicy test helpers: `assert_authorized_to`, `assert_have_authorized_scope`
- System tests use Capybara/Selenium
- Parallel test execution enabled

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
- Stimulus controllers in `/app/javascript/controllers/` (30+ controllers)
  - Key controllers: `refresh_minutes_controller` (timer), `combobox_controller`, `modal_controller`, `flatpickr_controller` (date picker)
- Tailwind CSS with @tailwindcss/forms and @tailwindcss/typography
- Build: esbuild for JS bundling
- PostHog analytics integration

**Background Jobs:** Sidekiq with Redis (required for Hotwire functionality)

**Invitation System:** devise_invitable for user invitations with external project access

**Onboarding:** Multi-step wizard using Wicked gem (`OnboardingWizardController`)

## Model Concerns

**Deletable (Soft Delete):**
- Uses `discard` gem with `default_scope -> { kept }`
- Applied to: Project, Client, Task, TimeReg
- Use `discard` instead of `destroy`, `kept` scope for active records

**RateConvertible:**
- Converts between currency format and hundredths (100 = 1.00)
- Applied to: Project, AssignedTask
- Use `rate_currency` reader/writer for formatted values

**Paper Trail:**
- Audit trail enabled on TimeReg model
- Query history with `time_reg.versions`

## Services

Business logic lives in `/app/services/`:
- `ProjectInvitationService` - Creates and processes project invitations
- `InviteUsersService` - Handles user invitation workflow
- `ConvertCurrencyHundredths` - Currency conversion utility

## Localization

- Supported locales: `en` (English), `nb` (Norwegian Bokmål)
- Locale files in `/config/locales/`
- User locale preference stored in User model

## Email Integration

- SendGrid for transactional emails
- Template IDs configured per locale in `/config/emails.yml`
- Templates: welcome, password reset, project invitations

## Configuration Files

- `/config/emails.yml` - SendGrid template IDs by locale
- `/config/currencies.yml` - Supported currencies (21K+)
- `/config/sidekiq_scheduler.yml` - Scheduled job definitions
- `.env.sample` - Required environment variables template
