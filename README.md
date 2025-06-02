![Frame 1000003871(1)](https://github.com/user-attachments/assets/0e60c1df-c3e7-44da-99d7-f16b1ab01551)

# Stemplin time tracking
Stemplin is a time tracking application written in Ruby on Rails.

### Setting Up Locally
Make sure you have the correct versions according to the Gemfile.

Install the project's dependencies by running:

```shell
bundle install
rails assets:precompile
rails db:create
rails db:migrate
yarn install
```

Populate the database from fixtures:

```shell
rails db:fixtures:load
```

### Redis
Hotwire will not work without Redis. If it is not running, start it with:

```shell
redis-server --daemonize yes
```

### Run the project
Finally, you can run your project locally with:

```shell
bin/dev
```

Open your browser and visit <http://localhost:3000>, your project should be running!


## Lint

Run linter with:

```shell
bin/rubocop
```

## Authorization
This project uses [ActionPolicy](https://github.com/palkan/action_policy) for authorization.

### Rules
1. ALWAYS use `authorized_scope` when querying the database, to prevent data leakage.

2. Use `authorize!` in EVERY SINGLE controller action, and create a policy for EVERY SINGLE controller action.

### Action Policy concepts
#### Policies
Policies are used to limit a `current_user`'s access to controller methods.
Policies are defined like so:

- `user` holds the value of `current_user`

- `record` holds the value of whatever is passed in to the `authorize!` method.
If nothing is passed, `record` will hold the model class, that is based on the controller name.
In this case that class is `Client`
```ruby
# app/policies/time_reg_policy.rb

class TimeRegPolicy < ApplicationPolicy
  def index?
    # Allows all users to access the index action
    true
  end
end
```
```ruby
# app/policies/client_policy.rb

class ClientPolicy < ApplicationPolicy
  def index?
    # As the index action fetches an entire collection, `record` is not relevant
    # This allows organization_admins to access the action
    user.organization_admin?
  end

  def create?
    # Allows organization_admins in the Client's organization access to the action
    user.organization_admin? && user.current_organization == record.oragnization
  end
end
```
#### Scopes
Scopes are used to scope out records that the `current_user` can access in a collection.
Define a scope like so:
```ruby
# app/policies/time_reg_policy.rb

class TimeRegPolicy < ApplicationPolicy
  scope_for :relation, :own do |relation|
    # Scopes out the user's own TimeRegs
    relation.joins(:organization, :user).where(organizations: user.current_organization, user: user).distinct
  end
end
```
```ruby
# app/policies/client_policy.rb

class ClientPolicy < ApplicationPolicy
  scope_for :relation do |relation|
    # Scopes out Clients accessible for organization_admin
    if user.organization_admin?
      relation.joins(:organization).where(organizations: user.current_organization).distinct
    else
      relation.none
    end
  end
end
```
#### Example usage of policies and scopes

```ruby
# app/controllers/clients_controller.rb

class ClientsController < ApplicationController
  def index
    # Where the controller fetches an entire collection, 
    # use the `authorize!` method without passing in a record (implicitly)
    authorize!
    @clients = authorized_scope(Client, type: :relation).all
  end

  def show
    @client = authorized_scope(Client, type: :relation).find(params[:id])
    # Where the controller fetches a single record,
    # use the `authorize!` method passing in a record (explicitly)
    authorize! @client
  end

  def create
    # Use `authorized_scope` when initializing a record
    @client = authorized_scope(Client, type: :relation).new(client_params)
    # Use `authorize!` before saving a record
    authorize! @clinet

    @client.save!
  end
end
```
