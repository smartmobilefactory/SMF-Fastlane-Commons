# Setup Dependencies - pod install & `sh generate.sh` (optional: Phrase App)
private_lane :smf_super_setup_dependencies do |options|

  smf_pod_install
  smf_sync_with_phrase_app(@smf_fastlane_config[:build_variants][options[:build_variant].to_sym][:phrase_app])

  build_variant_config = @smf_fastlane_config[:build_variants][options[:build_variant].to_sym]

  smf_verify_itc_upload_errors(
      upload_itc: build_variant_config[:upload_itc],
      project_name: @smf_fastlane_config[:project][:project_name],
      target: build_variant_config[:target],
      build_scheme: build_variant_config[:scheme],
      itc_skip_version_check: build_variant_config[:itc_skip_version_check],
      username: build_variant_config[:itc_apple_id],
      itc_team_id: build_variant_config[:itc_team_id],
      bundle_identifier: build_variant_config[:bundle_identifier]
  )
end

lane :smf_setup_dependencies do |options|
  smf_super_setup_dependencies(options)
end

# increment_buildnumber
private_lane :smf_super_pipeline_increment_build_number do |options|

  smf_increment_build_number(
      build_variant: options[:build_variant],
      current_build_number: smf_get_build_number_of_app
  )

end

lane :smf_pipeline_increment_build_number do |options|
  smf_super_pipeline_increment_build_number(options)
end

# build (build to release)

private_lane :smf_super_build do |options|
  build_variant_config = @smf_fastlane_config[:build_variants][options[:build_variant].to_sym]

  smf_download_provisioning_profiles(
      team_id: build_variant_config[:team_id],
      apple_id: build_variant_config[:apple_id],
      use_wildcard_signing: build_variant_config[:use_wildcard_signing],
      bundle_identifier: build_variant_config[:bundle_identifier],
      use_default_match_config: build_variant_config[:match].nil?,
      match_read_only: build_variant_config[:match].nil? ? nil : build_variant_config[:match][:read_only],
      match_type: build_variant_config[:match].nil? ? nil : build_variant_config[:match][:type],
      extensions_suffixes: @smf_fastlane_config[:extensions_suffixes],
      build_variant: options[:build_variant]
  )

  smf_build_ios_app(
      scheme: build_variant_config[:scheme],
      should_clean_project: build_variant_config[:should_clean_project],
      required_xcode_version: @smf_fastlane_config[:project][:xcode_version],
      project_name: @smf_fastlane_config[:project][:project_name],
      xcconfig_name: smf_get_xcconfig_name(options[:build_variant].to_sym),
      code_signing_identity: build_variant_config[:code_signing_identity],
      upload_itc: build_variant_config[:upload_itc].nil? ? false : build_variant_config[:upload_itc],
      upload_bitcode: build_variant_config[:upload_bitcode].nil? ? true : build_variant_config[:upload_bitcode],
      export_method: build_variant_config[:export_method],
      icloud_environment: smf_get_icloud_environment(options[:build_variant].to_sym)
  )
end

lane :smf_build do |options|
  smf_super_build(options)
end

# changelog
private_lane :smf_super_changelog do |options|
  smf_git_changelog(build_variant: options[:build_variant])
end

lane :smf_changelog do |options|
  smf_super_changelog(options)
end

# Upload Dsym
private_lane :smf_super_upload_dsyms do |options|

  build_variant_config = @smf_fastlane_config[:build_variants][options[:build_variant].to_sym]

  smf_upload_to_sentry(
    build_variant: options[:build_variant],
    org_slug: @smf_fastlane_config[:sentry_org_slug],
    project_slug: @smf_fastlane_config[:sentry_project_slug],
    build_variant_org_slug: build_variant_config[:sentry_org_slug],
    build_variant_project_slug: build_variant_config[:sentry_project_slug]
  )

end

lane :smf_upload_dsyms do |options|
  smf_super_upload_dsyms(options)
end

# Upload Appcenter
private_lane :smf_super_upload_to_appcenter do |options|
  build_variant = options[:build_variant]
  build_variant_config = @smf_fastlane_config[:build_variants][options[:build_variant].to_sym]
  
  # Upload the IPA to AppCenter
  smf_ios_upload_to_appcenter(
      build_number: smf_get_build_number_of_app,
      app_secret: smf_get_app_secret(build_variant),
      escaped_filename: build_variant_config[:scheme].gsub(' ', "\ "),
      path_to_ipa_or_app: smf_path_to_ipa_or_app(build_variant),
      is_mac_app: build_variant_config[:use_sparkle],
      podspec_path: build_variant_config[:podspec_path]
  )
end

lane :smf_upload_to_appcenter do |options|
  smf_super_upload_to_appcenter(options)
end

# Upload iTunes
private_lane :smf_super_upload_to_itunes do |options|

  build_variant_config = @smf_fastlane_config[:build_variants][options[:build_variant].to_sym]

  smf_upload_to_testflight(
      build_variant: options[:build_variant],
      apple_id: build_variant_config[:itc_apple_id],
      itc_team_id: build_variant_config[:itc_team_id],
      username: build_variant_config[:itc_apple_id],
      skip_waiting_for_build_processing: build_variant_config[:itc_skip_waiting].nil? ? false : build_variant_config[:itc_skip_waiting],
      slack_channel: @smf_fastlane_config[:slack_channel],
      bundle_identifier: build_variant_config[:bundle_identifier],
      upload_itc: build_variant_config[:upload_itc]
  )
end

lane :smf_upload_to_itunes do |options|
  smf_super_upload_to_itunes(options)
end


# Push git tag / Release
private_lane :smf_super_release do |options|

  smf_git_pull(options[:local_branch])
  smf_push_to_git_remote(local_branch: options[:local_branch])

  # Create the GitHub release
  build_number = get_build_number(xcodeproj: "#{@smf_fastlane_config[:project][:project_name]}.xcodeproj")
  smf_create_github_release(
      release_name: "#{options[:build_variant].upcase} #{build_number}",
      tag: get_tag_of_app(options[:build_variant], build_number),
      branch: options[:local_branch],
      build_variant: options[:build_variant]
  )
end

lane :smf_release do |options|
  smf_super_release(options)
end

# Slack
private_lane :smf_super_slack do |options|
  smf_send_default_build_success_notification(
      build_variant: options[:build_variant],
      name: get_default_name_of_app(options[:build_variant])
  )
end

lane :smf_slack do |options|
  smf_super_slack(options)
end

# Monitoring (MetaJSON)