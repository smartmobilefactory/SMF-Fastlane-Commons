private_lane :smf_upload_to_testflight do |options|

  if options[:upload_itc] == false
    UI.message("Upload to iTunes Connect is not enabled for this project.")
    next
  end

  username = !options[:username].nil? ? options[:username] : 'development@smfhq.com'
  itc_team_id = options[:itc_team_id]
  apple_id = !options[:apple_id].nil? ? options[:apple_id] : 'development@smfhq.com'
  skip_waiting_for_build_processing = options[:skip_waiting_for_build_processing]

  _smf_itunes_precheck(
      options[:build_variant],
      options[:slack_channel],
      options[:app_identifier],
      username
  )

  ENV["FASTLANE_ITC_TEAM_ID"] = itc_team_id

  UI.important("Uploading the build to Testflight.")
  upload_to_testflight(
      apple_id: apple_id,
      team_id: itc_team_id,
      username: username,
      skip_waiting_for_build_processing: skip_waiting_for_build_processing,
  )
end

def _smf_itunes_precheck(build_variant, slack_channel, app_identifier, username)

  begin

    precheck(
        username: username.nil? ? nil : username,
        app_identifier: app_identifier
    )

  rescue => exception

    title = "Fastlane Precheck found Metadata issues in iTunes Connect for #{get_default_name_of_app(build_variant)} 😢"
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