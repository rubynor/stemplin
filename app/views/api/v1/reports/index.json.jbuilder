json.total_minutes @total_minutes
json.total_entries @total_entries

json.by_project @by_project do |row|
  json.project_id row.project_id
  json.project_name row.project_name
  json.client_name row.client_name
  json.total_minutes row.total_minutes.to_i
  json.total_entries row.total_entries.to_i
end

json.by_user @by_user do |row|
  json.user_id row.user_id
  json.user_name "#{row.first_name} #{row.last_name}".strip
  json.total_minutes row.total_minutes.to_i
  json.total_entries row.total_entries.to_i
end
