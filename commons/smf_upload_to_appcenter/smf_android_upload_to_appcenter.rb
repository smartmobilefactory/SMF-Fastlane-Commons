private_lane :smf_android_upload_to_appcenter do |options|

  apk_path = options[:apk_path]
  aab_path = options[:aab_path]
  app_id = options[:app_id]
  destinations = options[:destinations].nil? ? "Collaborators" : options[:destinations]

  app_name, owner_name = get_app_details(app_id)
  UI.important('APK path is null.') if apk_path.nil?
  UI.important("AAB path is null.") if aab_path.nil?

  UI.message('Upload android app to AppCenter.')
  if !aab_path.nil?
    appcenter_upload(
        api_token: ENV[$SMF_APPCENTER_API_TOKEN_ENV_KEY],
        owner_name: owner_name,
        app_name: app_name,
        aab: aab_path,
        destination_type: 'store',
        destinations: destinations,
        notify_testers: true,
        release_notes: smf_read_changelog
    )
  else
    appcenter_upload(
        api_token: ENV[$SMF_APPCENTER_API_TOKEN_ENV_KEY],
        owner_name: owner_name,
        app_name: app_name,
        apk: apk_path,
        destinations: destinations,
        notify_testers: true,
        release_notes: smf_read_changelog
    )
  end

end

def get_app_details(app_id)
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
  UI.message("app_name: #{app_name}, owner_name: #{owner_name}")
  [app_name, owner_name]
end