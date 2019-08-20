private_lane :smf_upload_to_appcenter do |options|

  build_variant = options[:build_variant]
  apkFile = options[:apkFile]
  apkPath = options[:apkPath]
  UI.message("build_variant: #{build_variant}")
  app_secret = get_app_secret(build_variant)
  UI.message("app_secret: #{app_secret}")

  uri = URI.parse('https://api.appcenter.ms/v0.1/apps')
  request = Net::HTTP::Get.new(uri.request_uri)
  request['accept'] = 'application/json'
  request['X-API-Token'] = ENV[$SMF_APPCENTER_API_TOKEN_ENV_KEY]
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  t1 = Time.now
  response = http.request(request)
  t2 = Time.now
  UI.message("Request took #{t2 - t1} seconds.")
  if response.code != "200"
    raise("An error occured while fetching apps from AppCenter: #{response.message}")
  end
  UI.message(response.body)
  data = JSON.parse(response.body)
  project_app = data.find { |app| app['app_secret'].to_s.gsub!('-', '') == app_secret }
  if project_app.nil?
    raise("There is no app with the app secret: #{app_secret}")
  end
  app_name = project_app['name']
  owner_name = project_app['owner']['name']
  UI.message("app_name: #{app_name}, owner_name: #{owner_name}")

  case @platform
  when :ios
    dsym_path = Pathname.getwd.dirname.to_s + "/build/#{app_name}.app.dSYM.zip"
    UI.message("Constructed the dsym path \"#{dsym_path}\"")
    unless File.exist?(dsym_path)
      dsym_path = nil
      UI.message("Using nil as dsym_path as no file exists at the constructed path.")
    end

    NO_APP_FAILURE = "NO_APP_FAILURE"

    app_path = Pathname.getwd.dirname.to_s + "/build/#{app_name}.app.zip"
    app_path = Pathname.getwd.dirname.to_s + "/build/#{app_name}.app" unless (File.exists?(app_path))

    UI.message("Constructed path \"#{app_path}\" from filename \"#{app_name}\"")

    unless File.exist?(app_path)
      app_path = lane_context[SharedValues::IPA_OUTPUT_PATH]

      UI.message("Using \"#{app_path}\" as app_path as no file exists at the constructed path.")
    end

    appcenter_upload(
        api_token: ENV[$SMF_APPCENTER_API_TOKEN_ENV_KEY],
        owner_name: owner_name,
        app_name: app_name,
        ipa: app_path,
        dsym: dsym_path,
        notify_testers: true,
        release_notes: ENV[$SMF_CHANGELOG_ENV_KEY].to_s
    )
  when :android
    if apkPath
      found = true
      apk_path = apkPath
    else
      found = false
      lane_context[SharedValues::GRADLE_ALL_APK_OUTPUT_PATHS].each do |apk_path|
        found = apk_path.include? apkFile
        break if found
      end
    end

    raise("Cannot find the APK #{apkFile}") unless found

    UI.important("Uploading to HockeyApp (id: \"#{hockeyAppId}\") apk: #{apk_path}")

    appcenter_upload(
        api_token: ENV[$SMF_APPCENTER_API_TOKEN_ENV_KEY],
        owner_name: owner_name,
        app_name: app_name,
        apk: apk_path,
        notify_testers: true,
        release_notes: ENV[$SMF_CHANGELOG_ENV_KEY].to_s
    )
  when :flutter
    UI.message('Upload to AppCenter for flutter is not implemented yet')
  else
    UI.message("There is no platform \"#{@platform}\", exiting...")
    raise 'Unknown platform'
  end

end