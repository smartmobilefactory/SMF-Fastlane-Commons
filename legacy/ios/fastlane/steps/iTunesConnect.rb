#########################################
### smf_download_dsym_from_testflight ###
#########################################

desc "Download the dsym from iTunes Connect"
private_lane :smf_download_dsym_from_testflight do |options|

  UI.important("Download dsym from Testflight")

  # Variables
  project_name = @smf_fastlane_config[:project][:project_name]
  build_variant_config = @smf_fastlane_config[:build_variants][@smf_build_variant_sym]
  bundle_identifier = build_variant_config[:bundle_identifier]
  username = build_variant_config[:itc_apple_id]

  build_number = get_build_number(
    xcodeproj: "#{project_name}.xcodeproj"
    ).to_s

  download_dsyms(
    username: username,
    app_identifier: bundle_identifier,
    build_number: build_number
    )

end

################################
###   smf_itunes_precheck    ###
################################

private_lane :smf_itunes_precheck do |options|

  # Variables
  project_config = @smf_fastlane_config[:project]
  project_name = project_config[:project_name]
  slack_channel = project_config[:slack_channel]

  build_variant_config = @smf_fastlane_config[:build_variants][@smf_build_variant_sym]

  begin
    app_identifier = build_variant_config[:bundle_identifier]
    username = build_variant_config[:itc_apple_id]

    precheck(
      username: username.nil? ? nil : username,
      app_identifier: app_identifier
      )

  rescue => exception

    title = "Fastlane Precheck found Metadata issues in iTunes Connect for #{smf_default_notification_release_title} 😢"
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

##############
### HELPER ###
##############

def should_skip_waiting_after_itc_upload
  build_variant_config = @smf_fastlane_config[:build_variants][@smf_build_variant_sym]
  return (build_variant_config[:itc_skip_waiting].nil? ? false : build_variant_config[:itc_skip_waiting])
end
