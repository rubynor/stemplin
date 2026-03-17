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
3. **New:** The `ProjectShare` is created for the organization passed to `accept!(organization)` — this is the org the user chose to accept into, not an implicit "user's default org." A user who belongs to multiple orgs selects which org context to accept under.
4. `ProjectShare.find_or_create_by!(project: project, organization: organization)` with `rate: 0`

Subsequent invitations to users from the same org reuse the existing `ProjectShare`.

### Disconnecting

**Org_one disconnects org_two:**
1. Destroy the `ProjectShare` (cascades to `ProjectShareTaskRate` records)
2. Destroy all `ProjectAccess` records for org_two users on this project
3. Cancel pending `ProjectInvitation` records where `invited_email` matches existing org_two users (by email lookup against org_two's `access_infos → users`). Invitations to not-yet-registered users cannot be reliably matched — they remain pending and will fail validation if accepted after disconnection (since `ProjectAccess` creation would succeed but the `ProjectShare` would be absent).
4. Time_regs are preserved (they reference `assigned_task`, not `project_access`)

**Org_two disconnects from project:**
- Same as above — destroys their `ProjectShare` and their users' `ProjectAccess` records
- Time_regs preserved

### Post-Disconnection Time_Reg Visibility

After disconnection, time_regs from org_two users remain in the database linked to `assigned_task → project → client → org_one`. These time_regs are:
- **Visible to org_one admins**: They own the project and see all time_regs on it (existing behavior via `TimeRegPolicy` scoping through project organization).
- **Invisible to org_two**: The `ProjectShare` no longer exists, so org_two admins lose read access. Org_two members lose `ProjectAccess`, so they also lose visibility. This is intentional — disconnection severs the relationship.
- **Org_two users' own time_regs**: For personal history purposes, org_two users can still see their own time_regs via the `user_id` scope (the existing `TimeRegPolicy` allows users to see their own entries regardless of project ownership).

### Soft Delete Interaction

When org_one soft-deletes (discards) a shared project:
- The project's `default_scope -> { kept }` hides it from all queries
- `ProjectShare` records remain in the database but are effectively orphaned
- No automatic disconnection is triggered — the shares are inert while the project is discarded
- If the project is later restored (undiscarded), the shares resume functioning
- If the project is permanently destroyed, `dependent: :destroy` on `has_many :project_shares` cascades the deletion

## Authorization & Scoping

### Guest Org Admin Permissions

When a `ProjectShare` exists between a project and org_two, org_two admins can:
- View the project (name, description, tasks)
- View ALL time_regs on the project (from any org)
- View org_one user names on time_regs (first_name, last_name only — no email or other details)
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

### Guest Org Spectator Permissions

Org_two spectators follow the same rules as regular spectators: read-only access to projects they can see. If a spectator has `ProjectAccess` to a shared project, they can view the project and time_regs on it (scoped the same as today's spectator behavior). They cannot log time.

### Policy Changes

**ProjectPolicy scope (`:own`) — uses subquery approach to avoid JOIN incompatibility:**

```ruby
scope_for :relation, :own do |relation|
  own_ids = relation.joins(client: :organization)
                    .where(organizations: { id: organization.id })
                    .select(:id)

  shared_ids = relation.joins(:project_shares)
                       .where(project_shares: { organization_id: organization.id })
                       .select(:id)

  combined = relation.where(id: own_ids).or(relation.where(id: shared_ids))

  unless user.organization_admin?
    combined = combined.where(id: ProjectAccess.where(access_info: user.access_info(organization))
                                               .select(:project_id))
  end
  combined.distinct
end
```

Org_two admins see shared projects automatically via `ProjectShare` (no individual `ProjectAccess` needed). Org_two non-admin users still require individual `ProjectAccess`.

**TimeRegPolicy — action methods and scopes:**

The existing action methods check `record.organization == user.current_organization`, which resolves through the project's owning org. For shared projects, this check fails for guest org users. Introduce a helper:

```ruby
class TimeRegPolicy < ApplicationPolicy
  private

  def on_shared_project?
    ProjectShare.exists?(project: record.project, organization: user.current_organization)
  end

  def admin_of_shared_project?
    user.organization_admin? && on_shared_project?
  end

  public

  # show/edit/update/destroy — user can manage their own, or owning-org admin,
  # or guest-org admin can READ (show only, not edit/update/destroy)
  def show?
    user == record.user || is_admin_allowed || admin_of_shared_project?
  end

  %i[edit update destroy toggle_active].each do |action|
    define_method("#{action}?") do
      is_admin_allowed = user.organization_admin? && record.organization == user.current_organization
      user == record.user || is_admin_allowed
    end
  end

  def create?
    return false if user.access_info.organization_spectator?

    same_organization = user.current_organization == record.organization
    no_organization = record.organization.nil?
    shared_project = on_shared_project?

    if user.organization_admin?
      same_organization
    else
      # Allow if same org, no org (new record), or on a shared project (own entries only)
      ((same_organization || no_organization || shared_project) && record.user == user)
    end
  end

  # Scope: admins see own org + shared project time_regs
  # Members see only their own time_regs
  scope_for :relation do |relation|
    organization = user.current_organization
    shared_project_ids = ProjectShare.where(organization_id: organization.id).select(:project_id)

    if user.organization_admin?
      own = relation.joins(:organization).where(organizations: { id: organization.id })
      on_shared = relation.joins(assigned_task: :project).where(projects: { id: shared_project_ids })
      own.or(on_shared).distinct
    elsif user.access_info.organization_spectator?
      projects = authorized_scope(Project.all, type: :relation).all
      relation.joins(:project).where(projects: projects).distinct
    else
      # Non-admin members: own time_regs only (covers both owned and shared projects)
      relation.where(user: user).distinct
    end
  end
end
```

Key changes:
- `show?` allows guest org admins to **read** any time_reg on shared projects
- `edit?`/`update?`/`destroy?` unchanged — only own entries or owning-org admin
- `create?` allows guest org members to create their own time_regs on shared projects
- Default scope includes shared project time_regs for guest org admins
- Non-admin members use `user: user` scope which naturally includes their entries on shared projects

**Export restrictions:** The `export` action must exclude email addresses for cross-org time_regs. When exporting time_regs from a shared project, only include `first_name` and `last_name` for users from other organizations — not their email.

**TaskPolicy scope — extended for shared projects:**

The existing scope filters tasks to the current organization. For shared projects, org_two users need to see org_one's tasks (which are assigned to the project). The scope is extended:

```ruby
scope_for :relation do |relation|
  if user.organization_admin?
    # Own org tasks + tasks assigned to shared projects
    own = relation.where(organization: user.current_organization)
    shared_project_ids = ProjectShare.where(organization_id: user.current_organization.id).select(:project_id)
    on_shared = relation.joins(:assigned_tasks).where(assigned_tasks: { project_id: shared_project_ids })
    own.or(on_shared).distinct
  elsif user.access_info.organization_spectator?
    projects = authorized_scope(Project.all, type: :relation).all
    relation.joins(:projects).where(projects: projects).distinct
  else
    # Non-admin: own org tasks + tasks on shared projects they have access to
    own = relation.joins(:users).where(organization: user.current_organization, users: { id: user.id })
    user_shared_project_ids = ProjectAccess.joins(:access_info)
                                           .where(access_infos: { user_id: user.id, organization_id: user.current_organization.id })
                                           .joins(:project)
                                           .merge(Project.joins(:project_shares).where(project_shares: { organization_id: user.current_organization.id }))
                                           .select(:project_id)
    on_shared = relation.joins(:assigned_tasks).where(assigned_tasks: { project_id: user_shared_project_ids })
    own.or(on_shared).distinct
  end
end
```

Key changes:
- Admin scope: includes tasks assigned to any project shared with their org
- Member scope: includes tasks assigned to shared projects they have `ProjectAccess` to
- Spectator scope: unchanged (derives from authorized project scope)

**Workspace::ProjectPolicy — extended for guest admin read access:**

The workspace project policy must allow guest org admins to view (but not edit) shared projects. Add a `show?` override that permits access when a `ProjectShare` exists for the user's current organization. `edit?`, `update?`, `destroy?` remain restricted to the owning org's admins.

**New policies:**

`ProjectSharePolicy`:
- `show?` — org_one admin or org_two admin (either side can view the share)
- `update?` — org_two admin only (manage their rates)
- `destroy?` — org_one admin or org_two admin (either side can disconnect)
- Scope: projects shared with the current organization

`ProjectShareTaskRatePolicy`:
- `create?`, `update?`, `destroy?` — org_two admin only (manage their task rates)
- Scope: task rates belonging to the current org's project shares

**New policy actions on ProjectPolicy:**
- `manage_share?` — org_one admin only (view shared orgs, disconnect guest org)
- `disconnect_share?` — org_two admin (disconnect own org)

### Client Scope

**ClientPolicy scope:** Not extended — guest orgs do not browse org_one's client list. Shared projects appear directly in the project list. Report filters for guest orgs show the shared project directly without the client hierarchy.

## Rate Management

### Rate Ownership

| Who | Project rate | Task rates |
|-----|-------------|------------|
| Org_one (owner) | `project.rate` | `assigned_task.rate` |
| Org_two (guest) | `project_share.rate` | `project_share_task_rate.rate` |

### Rate Resolution

Rate resolution is context-dependent — it requires knowing which organization is viewing.

**`TimeReg#used_rate` refactoring:**

The existing `used_rate` method returns the owning org's rate. For shared projects, introduce a context-aware method:

```ruby
# New method that accepts an organization for rate context
def used_rate_for(organization)
  project_share = project.project_shares.find_by(organization: organization)
  if project_share
    task_rate = project_share.project_share_task_rates.find_by(assigned_task: assigned_task)
    rate = task_rate&.rate || 0
    rate.positive? ? rate : project_share.rate
  else
    # Owning org — existing behavior
    assigned_task.rate.positive? ? assigned_task.rate : project.rate
  end
end

# Keep existing method for backward compatibility
def used_rate
  assigned_task.rate.positive? ? assigned_task.rate : project.rate
end
```

Reports and billing call `used_rate_for(current_organization)` instead of `used_rate`. The existing `used_rate` continues to work for contexts where only the owning org's rate matters.

**Reports refactoring:** `Reports::Summary#total_billable_amount` and `Reports::Result` both call `billed_amount` which uses `used_rate` without org context. These must be updated to accept an organization parameter and use `used_rate_for(organization)`. The `billed_amount` method should gain a `billed_amount_for(organization)` variant following the same pattern.

### AssignedTask Rate-Change Archiving

When `AssignedTask#handle_rate_change` archives an old record and creates a new one, `ProjectShareTaskRate` records referencing the old `assigned_task_id` must be migrated:

```ruby
# In handle_rate_change, after creating new_assigned_task:
ProjectShareTaskRate.where(assigned_task: self).update_all(assigned_task_id: new_assigned_task.id)
```

This preserves guest org task rates across rate changes.

### Currency

Each org has its own currency. Rates on `ProjectShare` and `ProjectShareTaskRate` are in the guest org's currency (inferred from `project_share.organization.currency`). No cross-currency conversion — each org sees their own rates in their own currency.

### Rate Management UI

Org_two admins see a "Rates" section when viewing a shared project, where they can:
- Set their org's project-level rate on the `ProjectShare`
- Set per-task rates via `ProjectShareTaskRate` for each `AssignedTask`

This is separate from the project edit page (which org_two cannot access).

## Controller Structure

### New Controllers

**`Workspace::ProjectSharesController`** — manages the org-to-org relationship:
- `index` — list guest orgs for a project (org_one admin) or list shared projects (org_two admin)
- `update_rates` — org_two admin bulk-updates their project rate + task rates on the `ProjectShare`
- `destroy` — either side disconnects

**`Workspace::ProjectShareTaskRatesController`** — manages individual per-task rates for guest orgs:
- `create` / `update` — org_two admin sets individual task rates (used by the `update_rates` form)
- Nested under project_share routes

### Existing Controller Changes

**`Workspace::ProjectsController`:**
- `show` — detect if project is shared (guest org context), render read-only view
- Time_reg listing extended to show all entries on shared projects for guest admins

### Routes

```ruby
namespace :workspace do
  resources :projects do
    resources :project_shares, only: [:index, :destroy] do
      resources :project_share_task_rates, only: [:create, :update]
      member do
        patch :update_rates  # Bulk update project + task rates
      end
    end
  end
end
```

## API Considerations

The API layer (`Api::V1::*`) uses the same policies, so policy scope changes automatically apply. However:
- `Api::V1::ReportsController` does SQL-level aggregation — rate resolution must happen at the query level or post-processing, not just in Ruby
- API responses for shared projects should include a `shared: true` flag and `owner_organization` info
- API rate endpoints need to respect the same org-context rules

These are implementation details to address during the API phase, not blockers for the initial implementation.

## UI & Navigation

### Org_one Admin (Project Owner)

- Project show page gains a "Shared with" section listing guest organizations (name only) with a "Disconnect" action per org
- Existing "Invite external user" flow unchanged (email-based)
- Time_regs view unchanged

### Org_two Admin (Guest Org)

- Shared projects appear in the project list, visually distinguished with a badge/tag showing the owning org name
- Project show page is **read-only**: project details, task list, all time_regs
- Time_regs show user names (first_name, last_name) for all orgs
- A "Rates" tab/section for managing their org's rates
- A "Disconnect" action to leave the shared project

### Org_two Member (Invited User)

- Shared project appears in their project list (via `ProjectAccess`, same as today)
- Can create/edit/delete their own time_regs
- Sees tasks defined by org_one
- Does not see rates (same as regular non-admin members)

### Navigation

No new top-level navigation. Shared projects are mixed into the existing projects list with a visual indicator of ownership.

## Edge Cases

### Multi-org users
A user belonging to both org_one and org_two sees the project in both org contexts. When switching organizations, their permissions change accordingly (admin in org_one = full control, member in org_two = member-level access on the shared project). The `current_organization` determines which context applies.

### User promoted to admin in guest org
If an org_two member with `ProjectAccess` is promoted to admin, they gain full guest-admin read access to the shared project. Their existing `ProjectAccess` record becomes redundant (admins see shared projects via `ProjectShare`) but is harmless to keep.

### All guest org users removed but ProjectShare remains
If all org_two users' `ProjectAccess` records are individually removed (without disconnecting the org), the `ProjectShare` remains. Org_two admins still see the project. This is acceptable — the org-level share persists until explicitly disconnected.
