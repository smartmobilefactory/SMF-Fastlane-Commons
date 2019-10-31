private_lane :smf_ios_upload_to_hockey do |options|

  build_number = options[:build_number]
  app_id = options[:app_id]
  escaped_filename = options[:escaped_filename]
  path_to_ipa_or_app = options[:path_to_ipa_or_app]
  is_mac_app = !options[:is_mac_app].nil? ? options[:is_mac_app] : false
  podspec_path = options[:podspec_path]

  dsym_path = Pathname.getwd.dirname.to_s + "/build/#{escaped_filename}.app.dSYM.zip"
  UI.message("Constructed the dsym path \"#{dsym_path}\"")
  unless File.exist?(dsym_path)
    dsym_path = nil
    UI.message('Using nil as dsym_path as no file exists at the constructed path.')
  end

  NO_APP_FAILURE = 'NO_APP_FAILURE'

  if !is_mac_app
    sh "cd ../build; zip -r9 \"#{escaped_filename}.ipa.zip\" \"#{escaped_filename}.ipa\" || echo #{NO_APP_FAILURE}"
  end

  app_path = path_to_ipa_or_app

  # TODO: fix hockey for macOS
  if is_mac_app
    UI.warn("Hockey not implemented for macOS apps yet 😬")
    next
    version_number = version_get_podspec(path: podspec_path)

    app_path = app_path.sub('.ipa', '.dmg')

    raise("DMG file #{app_path} does not exit. Nothing to upload.") unless File.exist?(app_path)


    UI.message('Upload mac app to Hockey.')
    hockey(
        api_token: ENV[$SMF_HOCKEYAPP_API_TOKEN_ENV_KEY],
        public_identifier: app_id,
        build_number: build_number,
        version: version_number,
        ipa: app_path,
        dsym: dsym_path,
        notify: "1",
        notes: ENV[$SMF_CHANGELOG_ENV_KEY].to_s
    )
  else
    UI.message('Upload iOS app to Hockey.')
    hockey(
        api_token: ENV[$SMF_HOCKEYAPP_API_TOKEN_ENV_KEY],
        public_identifier: app_id,
        ipa: app_path,
        dsym: dsym_path,
        notify: "1",
        notes: ENV[$SMF_CHANGELOG_ENV_KEY].to_s
    )
  end


end