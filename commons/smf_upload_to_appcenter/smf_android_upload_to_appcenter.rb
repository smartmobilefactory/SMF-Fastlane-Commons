private_lane :smf_android_upload_to_appcenter do |options|

  apk_file = options[:apk_file]
  apk_path = options[:apk_path]
  app_secret = options[:app_secret]

  app_name, owner_name = get_app_details(app_secret)

  raise("Cannot find the APK #{apk_file}") unless found

  UI.message('Upload android app to AppCenter.')
  appcenter_upload(
      api_token: ENV[$SMF_APPCENTER_API_TOKEN_ENV_KEY],
      owner_name: owner_name,
      app_name: app_name,
      apk: apk_path,
      notify_testers: true,
      release_notes: ENV[$SMF_CHANGELOG_ENV_KEY].to_s
  )

end

def get_app_details(app_secret)
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
  project_app = data.find { |app| app['app_secret'] == app_secret }

  if project_app.nil?
    raise("There is no app with the app secret: #{app_secret}")
  end

  app_name = project_app['name']
  owner_name = project_app['owner']['name']
  UI.message("app_name: #{app_name}, owner_name: #{owner_name}")
  [app_name, owner_name]
end