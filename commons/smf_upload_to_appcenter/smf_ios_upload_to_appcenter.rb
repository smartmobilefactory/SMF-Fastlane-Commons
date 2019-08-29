private_lane :smf_ios_upload_to_appcenter do |options|

  build_number = options[:build_number]
  app_secret = options[:app_secret]
  escaped_filename = options[:escaped_filename]
  path_to_ipa_or_app = options[:path_to_ipa_or_app]
  is_mac_app = !options[:is_mac_app].nil? ? options[:is_mac_app] : false
  podspec_path = options[:podspec_path]

  app_name, owner_name = get_app_details(app_secret)

  dsym_path = Pathname.getwd.dirname.to_s + "/build/#{escaped_filename}.app.dSYM.zip"
  UI.message("Constructed the dsym path \"#{dsym_path}\"")
  unless File.exist?(dsym_path)
    dsym_path = nil
    UI.message('Using nil as dsym_path as no file exists at the constructed path.')
  end

  NO_APP_FAILURE = 'NO_APP_FAILURE'

  unless is_mac_app
    sh "cd ../build; zip -r9 \"#{escaped_filename}.app.zip\" \"#{escaped_filename}.app\" || echo #{NO_APP_FAILURE}"
  end

  app_path = path_to_ipa_or_app

  if is_mac_app
    version_number = version_get_podspec(path: podspec_path)

    app_path = app_path.sub('.app', '.dmg')

    raise("DMG file #{app_path} does not exit. Nothing to upload.") unless File.exist?(app_path)


    UI.message('Upload mac app to AppCenter.')
    appcenter_upload(
        api_token: ENV[$SMF_APPCENTER_API_TOKEN_ENV_KEY],
        owner_name: owner_name,
        app_name: app_name,
        build_number: build_number,
        version: version_number,
        ipa: app_path,
        dsym: dsym_path,
        notify_testers: true,
        release_notes: ENV[$SMF_CHANGELOG_ENV_KEY].to_s
    )
  else
    UI.message('Upload iOS app to AppCenter.')
    appcenter_upload(
        api_token: ENV[$SMF_APPCENTER_API_TOKEN_ENV_KEY],
        owner_name: owner_name,
        app_name: app_name,
        ipa: app_path,
        dsym: dsym_path,
        notify_testers: true,
        release_notes: ENV[$SMF_CHANGELOG_ENV_KEY].to_s
    )
  end


end