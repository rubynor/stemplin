json.total_minutes @total_minutes
json.total_billable_minutes @total_billable_minutes

json.dates @entries_by_date do |date, time_regs|
  json.date date
  json.time_regs time_regs do |time_reg|
    assigned_task = time_reg.assigned_task
    project = assigned_task.project

    json.id time_reg.id
    json.date_worked time_reg.date_worked
    json.minutes time_reg.minutes
    json.notes time_reg.notes
    json.user_id time_reg.user_id
    json.user_name time_reg.user.name
    json.client_name project.client&.name
    json.project_id project&.id
    json.project_name project&.name
    json.project_billable project&.billable
    json.task_name assigned_task.task&.name
    json.rate assigned_task.rate.positive? ? assigned_task.rate : project.rate
    json.billed_amount time_reg.billed_amount
  end
end
