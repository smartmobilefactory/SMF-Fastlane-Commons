private_lane :smf_upload_to_testflight do |options|

  slack_channel = options[:slack_channel]

  if options[:upload_itc] != true
    UI.message("Upload to iTunes Connect is not enabled for this build variant.")
    next
  end

  required_xcode_version = options[:required_xcode_version]
  itc_team_id = options[:itc_team_id]
  username = !options[:apple_id].nil? ? options[:apple_id] : 'development@smfhq.com'
  itc_apple_id = options[:itc_apple_id]
  skip_waiting_for_build_processing = options[:skip_waiting_for_build_processing]

  ENV["FASTLANE_ITC_TEAM_ID"] = itc_team_id

  smf_setup_correct_xcode_executable_for_build(required_xcode_version: required_xcode_version)

  _smf_itunes_precheck(
      options[:build_variant],
      slack_channel,
      options[:bundle_identifier],
      username
  )

  UI.important("Uploading the build to Testflight.")
  upload_to_testflight(
      apple_id: itc_apple_id,
      team_id: itc_team_id,
      username: username,
      skip_waiting_for_build_processing: skip_waiting_for_build_processing,
      ipa: smf_path_to_ipa_or_app(options[:build_variant]).gsub('.zip', '')
  )
end

def _smf_itunes_precheck(build_variant, slack_channel, bundle_identifier, username)

  begin

    precheck(
        username: username.nil? ? nil : username,
        app_identifier: bundle_identifier
    )

  rescue => exception

    title = "Fastlane Precheck found Metadata issues in iTunes Connect for #{smf_get_default_name_of_app(build_variant)} 😢"
    message = "The build will continue to upload to iTunes Connect, but you may need to fix the Metadata issues before releasing the app."

    smf_send_message(
        title: title,
        message: message,
        type: "warning",
        exception: exception,
        slack_channel: slack_channel
    )
  end
end