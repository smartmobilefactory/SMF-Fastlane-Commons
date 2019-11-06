private_lane :smf_ios_upload_to_hockey do |options|
  app_id = options[:app_id]
  escaped_filename = options[:escaped_filename]
  path_to_ipa_or_app = options[:path_to_ipa_or_app]

  dsym_path = Pathname.getwd.dirname.to_s + "/build/#{escaped_filename}.app.dSYM.zip"
  UI.message("Constructed the dsym path \"#{dsym_path}\"")
  unless File.exist?(dsym_path)
    dsym_path = nil
    UI.message('Using nil as dsym_path as no file exists at the constructed path.')
  end

  NO_APP_FAILURE = 'NO_APP_FAILURE'

  sh "cd ../build; zip -r9 \"#{escaped_filename}.ipa.zip\" \"#{escaped_filename}.ipa\" || echo #{NO_APP_FAILURE}"


  app_path = path_to_ipa_or_app

  UI.message('Upload iOS app to Hockey.')
  hockey(
      api_token: ENV[$SMF_HOCKEYAPP_API_TOKEN_ENV_KEY],
      public_identifier: app_id,
      ipa: app_path,
      dsym: dsym_path,
      notify: "1",
      notes: smf_read_changelog
  )

end