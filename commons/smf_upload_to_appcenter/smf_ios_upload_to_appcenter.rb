private_lane :smf_ios_upload_to_appcenter do |options|

  build_variant = options[:build_variant]
  build_number = options[:build_number]
  app_id = options[:app_id]
  escaped_filename = options[:escaped_filename]
  path_to_ipa_or_app = options[:path_to_ipa_or_app]
  is_mac_app = !options[:is_mac_app].nil? ? options[:is_mac_app] : false
  destinations = options[:destinations].nil? ? 'Collaborators' : options[:destinations]
  sparkle_xml_name = options[:sparkle_xml_name]
  upload_sparkle = options[:upload_sparkle]

  app_name, owner_name, owner_id = get_app_details(app_id)

  dsym_path = "#{smf_workspace_dir}/build/#{escaped_filename}.app.dSYM.zip"
  UI.message("Constructed the dsym path \"#{dsym_path}\"")
  unless File.exist?(dsym_path)
    dsym_path = nil
    UI.message('Using nil as dsym_path as no file exists at the constructed path.')
  end

  NO_APP_FAILURE = 'NO_APP_FAILURE'

  app_path = path_to_ipa_or_app

  if is_mac_app
    version_number = smf_get_version_number(build_variant)
    app_path = app_path.sub('.app', '.dmg')

    raise("Binary file #{app_path} does not exist. Nothing to upload.") unless File.exist?(app_path)

    UI.message("app_path = #{app_path}")

    if upload_sparkle
      package_path = "#{app_path}.zip"
      sh "cd \"#{File.dirname(app_path)}\"; zip -r -q \"#{package_path}\" \"./#{escaped_filename}.dmg\" \"./#{escaped_filename}.html\" \"./#{sparkle_xml_name}\""
      app_path = package_path
    end

    UI.message("app_path = #{app_path}")

    UI.message('Upload mac app to AppCenter.')
    appcenter_upload(
        api_token: ENV[$SMF_APPCENTER_API_TOKEN_ENV_KEY],
        owner_name: owner_name,
        app_name: app_name,
        app_os: 'MacOS',
        build_number: build_number,
        version: version_number,
        file: app_path,
        dsym: dsym_path,
        notify_testers: true,
        destinations: destinations,
        release_notes: smf_read_changelog
    )
  else

    raise("Binary file #{app_path} does not exit. Nothing to upload.") unless File.exist?(app_path)

    UI.message('Upload iOS app to AppCenter.')
    appcenter_upload(
        api_token: ENV[$SMF_APPCENTER_API_TOKEN_ENV_KEY],
        owner_name: owner_name,
        app_name: app_name,
        file: app_path,
        dsym: dsym_path,
        notify_testers: true,
        destinations: destinations,
        release_notes: smf_read_changelog
    )
  end
end
