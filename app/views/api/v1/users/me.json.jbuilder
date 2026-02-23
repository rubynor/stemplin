json.partial! "api/v1/users/user", user: @user

json.api_token @user.api_token

json.current_organization do
  org = @user.current_organization
  if org
    json.id org.id
    json.name org.name
  else
    json.null!
  end
end
