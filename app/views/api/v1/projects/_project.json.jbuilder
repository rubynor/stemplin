json.extract! project, :id, :name, :description, :billable, :rate, :client_id, :created_at, :updated_at
json.rate_currency project.rate_currency
json.client_name project.client&.name
