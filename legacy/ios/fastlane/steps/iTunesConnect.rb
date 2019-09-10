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

