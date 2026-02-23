json.partial! "api/v1/projects/project", project: @project

json.assigned_tasks @assigned_tasks do |assigned_task|
  json.id assigned_task.id
  json.task_id assigned_task.task_id
  json.task_name assigned_task.task.name
  json.rate assigned_task.rate
  json.rate_currency assigned_task.rate_currency
end
