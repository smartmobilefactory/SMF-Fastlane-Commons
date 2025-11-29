private_lane :smf_upload_to_testflight do |options|

  slack_channel = options[:slack_channel]

  if options[:upload_itc] != true
    UI.message("Upload to TestFlight is not enabled for this build variant.")
    next
  end

  required_xcode_version = options[:required_xcode_version]
  itc_team_id = options[:itc_team_id]
  username = !options[:apple_id].nil? ? options[:apple_id] : 'development@smfhq.com'
  itc_apple_id = options[:itc_apple_id]
  skip_waiting_for_build_processing = options[:skip_waiting_for_build_processing] == true
  itc_platform = options[:itc_platform]

  # Create App Store Connect API key if environment variables are available
  api_key = nil
  if ENV['APP_STORE_CONNECT_API_KEY_ID'] && ENV['APP_STORE_CONNECT_API_KEY_ISSUER_ID'] && ENV['APP_STORE_CONNECT_API_KEY_PATH']
    UI.message('Using App Store Connect API key for authentication')
    api_key = app_store_connect_api_key(
      key_id: ENV['APP_STORE_CONNECT_API_KEY_ID'],
      issuer_id: ENV['APP_STORE_CONNECT_API_KEY_ISSUER_ID'],
      key_filepath: ENV['APP_STORE_CONNECT_API_KEY_PATH'],
      duration: 1200,
      in_house: false
    )
  else
    UI.message('Using username/password authentication (fallback)')
  end

  ENV["FASTLANE_ITC_TEAM_ID"] = itc_team_id

  smf_setup_correct_xcode_executable_for_build(required_xcode_version: required_xcode_version)

  _smf_itunes_precheck(
      options[:build_variant],
      slack_channel,
      options[:bundle_identifier],
      username,
      options[:precheck_include_in_app_purchases]
  )

  UI.important("Uploading the build to TestFlight.")
  upload_to_testflight(
      apple_id: itc_apple_id,
      team_id: itc_team_id,
      api_key: api_key,
      username: api_key ? nil : username,
      skip_waiting_for_build_processing: skip_waiting_for_build_processing,
      ipa: smf_path_to_ipa_or_app.gsub('.zip', ''),
      app_platform: itc_platform
  )
end

def _smf_itunes_precheck(build_variant, slack_channel, bundle_identifier, username, include_in_app_purchases = true)

  begin

    # Create API key for precheck if available
    api_key_for_precheck = nil
    if ENV['APP_STORE_CONNECT_API_KEY_ID'] && ENV['APP_STORE_CONNECT_API_KEY_ISSUER_ID'] && ENV['APP_STORE_CONNECT_API_KEY_PATH']
      api_key_for_precheck = app_store_connect_api_key(
        key_id: ENV['APP_STORE_CONNECT_API_KEY_ID'],
        issuer_id: ENV['APP_STORE_CONNECT_API_KEY_ISSUER_ID'],
        key_filepath: ENV['APP_STORE_CONNECT_API_KEY_PATH'],
        duration: 1200,
        in_house: false
      )
    end

    precheck(
        api_key: api_key_for_precheck,
        username: api_key_for_precheck ? nil : username,
        app_identifier: bundle_identifier,
        include_in_app_purchases: include_in_app_purchases
    )

  rescue => exception

    title = "Fastlane Precheck found Metadata issues in App Store Connect for #{smf_get_default_name_and_version(build_variant)} 😢"
    message = "The build will continue to upload to App Store Connect, but you may need to fix the Metadata issues before releasing the app."

    smf_send_message(
        title: title,
        message: message,
        type: "warning",
        exception: exception,
        slack_channel: slack_channel
    )
  end
end