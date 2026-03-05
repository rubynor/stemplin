json.extract! time_reg, :id, :notes, :minutes, :date_worked, :assigned_task_id, :user_id, :start_time, :created_at, :updated_at
json.current_minutes time_reg.current_minutes
json.active time_reg.active?
json.task_name time_reg.task&.name
json.project_id time_reg.project&.id
json.project_name time_reg.project&.name
json.client_name time_reg.client&.name
