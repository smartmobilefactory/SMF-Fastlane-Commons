
def smf_appcenter_get_app_details(app_id)
  uri = URI.parse('https://api.appcenter.ms/v0.1/apps')
  request = Net::HTTP::Get.new(uri.request_uri)
  request['accept'] = 'application/json'
  request['X-API-Token'] = ENV[$SMF_APPCENTER_API_TOKEN_ENV_KEY]
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  response = http.request(request)

  unless response.code == '200'
    raise("An error occured while fetching apps from AppCenter: #{response.message}")
  end

  data = JSON.parse(response.body)
  project_app = data.find { |app| app['app_secret'] == app_id }

  if project_app.nil?
    raise("There is no app with the app id: #{app_id}")
  end

  app_name = project_app['name']
  owner_name = project_app['owner']['name']
  owner_id = project_app['owner']['id']
  app_id = project_app['id']
  UI.message("app_name: #{app_name}, owner_name: #{owner_name}")
  [app_id, app_name, owner_name, owner_id]
end

#
# return json array which looks like:
# [
#   {
#     "id": "f44a82d1-21a3-4d93-bc20-7e4b72d7fab4",
#     "url": "https://us-central1-smf-hub.cloudfunctions.net/appcenter",
#     "name": "SmfHub",
#     "enabled": true,
#     "event_types": ["NewAppRelease"]
#   }
# ]
#
def smf_appcenter_get_webhooks(app_name, owner_name)
  uri = URI.parse("https://appcenter.ms/api/v0.1/apps/#{owner_name}/#{app_name}/alerts_webhooks")
  request = Net::HTTP::Get.new(uri.request_uri)
  request['accept'] = 'application/json'
  request['X-API-Token'] = ENV[$SMF_APPCENTER_API_TOKEN_ENV_KEY]
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  response = http.request(request)

  unless response.code == '200'
    raise("An error occured while fetching apps from AppCenter: #{response.message}")
  end

  data = JSON.parse(response.body)
  data['values']
end

#
# webhookdata:
# {
#   "name" => "SmfHub",
#   "url" => "https://us-central1-smf-hub.cloudfunctions.net/appcenter"
#   "enabled" => true
#   "event_types" => ["NewAppRelease"]
# }
#
def smf_appcenter_create_webhook(app_name, owner_name, webhookdata)
  uri = URI.parse("https://appcenter.ms/api/v0.1/apps/#{owner_name}/#{app_name}/alerts_webhooks")
  request = Net::HTTP::Post.new(uri.request_uri)
  request['Content-Type'] = 'application/json'
  request['X-API-Token'] = ENV[$SMF_APPCENTER_API_TOKEN_ENV_KEY]
  request.body = webhookdata.to_json

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  response = http.request(request)

  response.code == '200'
end

#
# notify firebase appcenter webhook
# AppCenter itself webhooks only called for the first destination group
#
def smf_appcenter_notify_destination_groups(app_id, app_name, owner_name, destinations_groups)
  api_token = ENV[$SMF_APPCENTER_API_TOKEN_ENV_KEY]
  destination_type = 'group'

  destinations_array = destinations_groups.split(',').drop(1)

  destinations_array.each do |destination_name|
    destination = Helper::AppcenterHelper.get_destination(api_token, owner_name, app_name, destination_type, destination_name)
    if destination
      destination_id = destination['id']

      uri = URI.parse($SMF_APPCENTER_WEBHOOK_URL)
      request = Net::HTTP::Post.new(uri.request_uri)
      request['Content-Type'] = 'application/json'
      request['X-API-Token'] = ENV[$SMF_APPCENTER_API_TOKEN_ENV_KEY]
      request.body = {
        "installable" => true,
        "app_id" => app_id,
        "distribution_group_id" => destination_id,
        "app_display_name" => app_name
      }.to_json

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      response = http.request(request)

      UI.success("additionally notified #{destination_type} '#{destination_name}' about the new release")
    else
      UI.error("#{destination_type} '#{destination_name}' was not found")
    end
  end
end
