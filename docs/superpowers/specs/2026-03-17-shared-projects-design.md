# Shared Projects Design Spec

## Overview

Allow organizations to share projects with other organizations. An admin from the owning organization invites external users by email. When a user from another organization accepts, an org-to-org relationship is automatically established. The owning org retains full control; guest org admins get read access to the project and all time entries; each org maintains independent rates.

## Requirements

1. **Org-to-org sharing**: Admin from org_one shares a project with org_two by inviting org_two users via email. The org-to-org link is created implicitly on first invitation acceptance.
2. **User selection**: Org_one admin selects specific org_two users (by email invitation, like today).
3. **Guest admin visibility**: Org_two admins can read ALL time_regs on the shared project (including org_one users' entries).
4. **Independent rates**: Each org sets their own project-level and task-level rates in their own currency.
5. **Shared task list**: Tasks are defined by org_one. Each org sets their own rate per task.
6. **Multiple guest orgs**: A project can be shared with any number of organizations.
7. **Disconnection**: Either side can disconnect. Time_regs are preserved.

## Data Model

### New Tables

#### `project_shares`

| Column | Type | Constraints |
|--------|------|------------|
| id | bigint | PK |
| project_id | bigint | NOT NULL, FK → projects |
| organization_id | bigint | NOT NULL, FK → organizations |
| rate | integer | DEFAULT 0 |
| created_at | datetime | NOT NULL |
| updated_at | datetime | NOT NULL |

- Unique index on `[project_id, organization_id]`
- `organization_id` refers to the **guest** organization (not the project owner)

#### `project_share_task_rates`

| Column | Type | Constraints |
|--------|------|------------|
| id | bigint | PK |
| project_share_id | bigint | NOT NULL, FK → project_shares |
| assigned_task_id | bigint | NOT NULL, FK → assigned_tasks |
| rate | integer | DEFAULT 0 |
| created_at | datetime | NOT NULL |
| updated_at | datetime | NOT NULL |

- Unique index on `[project_share_id, assigned_task_id]`

### New Models

#### `ProjectShare`

```ruby
class ProjectShare < ApplicationRecord
  include RateConvertible

  belongs_to :project
  belongs_to :organization

  has_many :project_share_task_rates, dependent: :destroy

  validates :organization_id, uniqueness: { scope: :project_id }
  validate :organization_is_not_project_owner

  private

  def organization_is_not_project_owner
    errors.add(:organization, :is_project_owner) if organization_id == project&.organization&.id
  end
end
```

#### `ProjectShareTaskRate`

```ruby
class ProjectShareTaskRate < ApplicationRecord
  include RateConvertible

  belongs_to :project_share
  belongs_to :assigned_task

  validates :assigned_task_id, uniqueness: { scope: :project_share_id }
end
```

### Existing Model Changes

**Project:**
- `has_many :project_shares, dependent: :destroy`
- `has_many :shared_organizations, through: :project_shares, source: :organization`

**Organization:**
- `has_many :project_shares, dependent: :destroy`
- `has_many :shared_projects, through: :project_shares, source: :project`

## Invitation & Sharing Flow

### Establishing the Org-to-Org Link

The existing `ProjectInvitationService` and `ProjectInvitation#accept!` flow is extended:

1. Org_one admin invites an external user by email (existing flow)
2. User accepts invitation (existing: creates `AccessInfo` + `ProjectAccess`)
3. **New:** If the user's organization differs from the project's organization, `find_or_create` a `ProjectShare` between the project and the user's organization
4. The `ProjectShare` is created with `rate: 0` (guest org admin sets rates later)

Subsequent invitations to users from the same org reuse the existing `ProjectShare`.

### Disconnecting

**Org_one disconnects org_two:**
1. Destroy the `ProjectShare` (cascades to `ProjectShareTaskRate` records)
2. Destroy all `ProjectAccess` records for org_two users on this project
3. Cancel pending `ProjectInvitation` records for org_two users
4. Time_regs are preserved (they reference `assigned_task`, not `project_access`)

**Org_two disconnects from project:**
- Same as above — destroys their `ProjectShare` and their users' `ProjectAccess` records
- Time_regs preserved

## Authorization & Scoping

### Guest Org Admin Permissions

When a `ProjectShare` exists between a project and org_two, org_two admins can:
- View the project (name, description, tasks)
- View ALL time_regs on the project (from any org)
- Manage their own org's rates (`ProjectShare` rate + `ProjectShareTaskRate` rates)
- Disconnect their org from the project

They cannot:
- Edit the project (name, description, tasks, billable status)
- Create/edit/delete time_regs for other orgs' users
- See other orgs' rates
- Manage project access (invitations are org_one admin's job)

### Guest Org Member Permissions

Org_two members with `ProjectAccess`:
- Can create/edit/delete their own time_regs
- Can view project details and task list
- Cannot see rates
- Cannot see other users' time_regs (unless they are admin)

### Policy Changes

**ProjectPolicy scope (`:own`):**

```ruby
scope_for :relation, :own do |relation|
  # Org's own projects
  own = relation.joins(client: :organization)
                .where(organizations: { id: organization.id })

  # Shared projects via ProjectShare
  shared = relation.joins(:project_shares)
                   .where(project_shares: { organization_id: organization.id })

  combined = own.or(shared)

  unless user.organization_admin?
    combined = combined.joins(:project_accesses)
                       .where(project_accesses: user.project_accesses)
  end
  combined.distinct
end
```

Org_two admins see shared projects automatically via `ProjectShare` (no individual `ProjectAccess` needed). Org_two non-admin users still require individual `ProjectAccess`.

**TimeRegPolicy:**

Extended so org_two admins can read (not write) all time_regs on shared projects. Org_two members can only read/write their own time_regs.

**New policy actions:**
- `project#manage_share?` — org_one admin only (disconnect guest org, manage sharing)
- `project#disconnect_share?` — org_two admin (disconnect own org)
- `project#view_shared?` — org_two admin read access

## Rate Management

### Rate Ownership

| Who | Project rate | Task rates |
|-----|-------------|------------|
| Org_one (owner) | `project.rate` | `assigned_task.rate` |
| Org_two (guest) | `project_share.rate` | `project_share_task_rate.rate` |

### Rate Resolution for Reports

1. Determine which org is viewing the report
2. If the org owns the project: use `assigned_task.rate` falling back to `project.rate` (existing behavior)
3. If the org is a guest: use `project_share_task_rate.rate` falling back to `project_share.rate`
4. If the guest org hasn't set rates (rate = 0): show as unset/zero

### Currency

Each org has its own currency. Rates on `ProjectShare` and `ProjectShareTaskRate` are in the guest org's currency. No cross-currency conversion — each org sees their own rates in their own currency.

### Rate Management UI

Org_two admins see a "Rates" section when viewing a shared project, where they can:
- Set their org's project-level rate on the `ProjectShare`
- Set per-task rates via `ProjectShareTaskRate` for each `AssignedTask`

This is separate from the project edit page (which org_two cannot access).

## UI & Navigation

### Org_one Admin (Project Owner)

- Project show page gains a "Shared with" section listing guest organizations with a "Disconnect" action per org
- Existing "Invite external user" flow unchanged (email-based)
- Time_regs view unchanged

### Org_two Admin (Guest Org)

- Shared projects appear in the project list, visually distinguished with a badge/tag showing the owning org name
- Project show page is **read-only**: project details, task list, all time_regs
- A "Rates" tab/section for managing their org's rates
- A "Disconnect" action to leave the shared project

### Org_two Member (Invited User)

- Shared project appears in their project list (via `ProjectAccess`, same as today)
- Can create/edit/delete their own time_regs
- Sees tasks defined by org_one
- Does not see rates (same as regular non-admin members)

### Navigation

No new top-level navigation. Shared projects are mixed into the existing projects list with a visual indicator of ownership.
