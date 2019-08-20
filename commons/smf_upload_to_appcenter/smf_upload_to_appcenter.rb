private_lane :smf_upload_to_appcenter do |options|

  build_variant = options[:build_variant]
  apkFile = options[:apkFile]
  apkPath = options[:apkPath]
  app_secret = get_app_secret(build_variant)

  uri = URI.parse('https://api.appcenter.ms/v0.1/apps')
  request = Net::HTTP::Get.new(uri.request_uri)
  request['accept'] = 'application/json'
  request['X-API-Token'] = ENV[$SMF_APPCENTER_API_TOKEN_ENV_KEY]
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  t1 = Time.now
  response = http.request(request)
  t2 = Time.now
  UI.message("Fetching apps from AppCenter took #{t2 - t1} seconds.")

  unless response.code == "200"
    raise("An error occured while fetching apps from AppCenter: #{response.message}")
  end

  data = JSON.parse(response.body)
  project_app = data.find { |app| app['app_secret'].to_s.gsub!('-', '') == app_secret }

  if project_app.nil?
    raise("There is no app with the app secret: #{app_secret}")
  end

  t3 = Time.now
  UI.message("Filter the project's app took #{t3 - t2} seconds.")

  app_name = project_app['name']
  owner_name = project_app['owner']['name']
  UI.message("app_name: #{app_name}, owner_name: #{owner_name}")

  case @platform
  when :ios
    escaped_filename = get_escaped_filename(build_variant)
    is_mac_app = is_mac_app(build_variant)
    build_number = get_build_number_of_app
    version_number = version_get_podspec(path: get_podspec_path(build_variant))
    dsym_path = Pathname.getwd.dirname.to_s + "/build/#{escaped_filename}.app.dSYM.zip"
    UI.message("Constructed the dsym path \"#{dsym_path}\"")
    unless File.exist?(dsym_path)
      dsym_path = nil
      UI.message("Using nil as dsym_path as no file exists at the constructed path.")
    end

    NO_APP_FAILURE = "NO_APP_FAILURE"

    unless is_mac_app
      sh "cd ../build; zip -r9 \"#{escaped_filename}.app.zip\" \"#{escaped_filename}.app\" || echo #{NO_APP_FAILURE}"
    end

    app_path = get_path_to_ipa_or_app(build_variant)

    if is_mac_app
      app_path = app_path.sub(".app", ".dmg")
      unless File.exist?(app_path)
        raise("DMG file #{app_path} does not exit. Nothing to upload.")
      end

      UI.message("Upload mac app to AppCenter.")
      appcenter_upload(
          api_token: ENV[$SMF_APPCENTER_API_TOKEN_ENV_KEY],
          owner_name: owner_name,
          app_name: app_name,
          build_number: build_number,
          version: version_number,
          ipa: app_path,
          dsym: dsym_path,
          notify_testers: false,
          release_notes: ENV[$SMF_CHANGELOG_ENV_KEY].to_s
      )
    else
      UI.message("Upload iOS app to AppCenter.")
      appcenter_upload(
          api_token: ENV[$SMF_APPCENTER_API_TOKEN_ENV_KEY],
          owner_name: owner_name,
          app_name: app_name,
          ipa: app_path,
          dsym: dsym_path,
          notify_testers: false,
          release_notes: ENV[$SMF_CHANGELOG_ENV_KEY].to_s
      )
    end

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

    UI.message("Upload android app to AppCenter.")
    appcenter_upload(
        api_token: ENV[$SMF_APPCENTER_API_TOKEN_ENV_KEY],
        owner_name: owner_name,
        app_name: app_name,
        apk: apk_path,
        notify_testers: false,
        release_notes: ENV[$SMF_CHANGELOG_ENV_KEY].to_s
    )
  when :flutter
    UI.message('Upload to AppCenter for flutter is not implemented yet')
  else
    UI.message("There is no platform \"#{@platform}\", exiting...")
    raise 'Unknown platform'
  end

end