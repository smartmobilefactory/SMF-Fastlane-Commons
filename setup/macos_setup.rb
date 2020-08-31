
########## PULLREQUEST CHECK LANES ##########

# Update Files

private_lane :smf_super_generate_files do |options|
  smf_update_generated_files(options)
end

lane :smf_generate_files do |options|
  smf_super_generate_files
end

# Setup Dependencies

private_lane :smf_super_setup_dependencies do |options|
  smf_pod_install
end

lane :smf_setup_dependencies_pr_check do |options|
  smf_super_setup_dependencies(options)
end

lane :smf_setup_dependencies_build do |options|
  smf_super_setup_dependencies(options)
end


# Build

private_lane :smf_super_build do |options|

  build_variant = !options[:build_variant].nil? ? options[:build_variant] : smf_get_first_variant_from_config
  build_variant_config = @smf_fastlane_config[:build_variants][build_variant.to_sym]

  smf_build_apple_app(
      skip_export: options[:skip_export].nil? ? false : options[:skip_export],
      skip_package_pkg: build_variant_config[:skip_package_pkg],
      scheme: build_variant_config[:scheme],
      should_clean_project: build_variant_config[:should_clean_project],
      required_xcode_version: @smf_fastlane_config[:project][:xcode_version],
      project_name: @smf_fastlane_config[:project][:project_name],
      xcconfig_name: smf_get_xcconfig_name(build_variant.to_sym),
      code_signing_identity: build_variant_config[:code_signing_identity],
      upload_itc: build_variant_config[:upload_itc].nil? ? false : build_variant_config[:upload_itc],
      upload_bitcode: build_variant_config[:upload_bitcode].nil? ? true : build_variant_config[:upload_bitcode],
      export_method: build_variant_config[:export_method],
      icloud_environment: smf_get_icloud_environment(build_variant.to_sym)
  )

  smf_rename_app_file(build_variant)
end

lane :smf_build do |options|
  smf_super_build(options)
end


# Unit-Tests

private_lane :smf_super_unit_tests do |options|

  build_variant = !options[:build_variant].nil? ? options[:build_variant] : smf_get_first_variant_from_config

  build_variant_config = @smf_fastlane_config[:build_variants][build_variant.to_sym]

  smf_ios_unit_tests(
      project_name: @smf_fastlane_config[:project][:project_name],
      unit_test_scheme: build_variant_config[:unit_test_scheme],
      scheme: build_variant_config[:scheme],
      unit_test_xcconfig_name: !build_variant_config[:xcconfig_name].nil? ? build_variant_config[:xcconfig_name][:unittests] : nil,
      device: build_variant_config["tests.device_to_test_against".to_sym],
      required_xcode_version: @smf_fastlane_config[:project][:xcode_version],
      testing_for_mac: true
  )

end

lane :smf_unit_tests do |options|
  smf_super_unit_tests(options)
end


# Linter

private_lane :smf_super_linter do
  smf_run_swift_lint
end

lane :smf_linter do |options|
  smf_super_linter
end


# Danger

private_lane :smf_super_pipeline_danger do |options|

  smf_danger
end

lane :smf_pipeline_danger do |options|
  smf_super_pipeline_danger(options)
end

# Report project data

private_lane :smf_super_report do |options|
  build_variant = options[:build_variant]

  smf_report_metrics(build_variant: build_variant, smf_get_meta_db_project_name: smf_get_meta_db_project_name)
end

lane :smf_report do |options|
  smf_super_report(options)
end

########## ADDITIONAL LANES USED FOR BUILDING ##########

# Generate Changelog

private_lane :smf_super_generate_changelog do |options|
  smf_git_changelog(build_variant: options[:build_variant])
end

lane :smf_generate_changelog do |options|
  smf_super_generate_changelog(options)
end


# Increment Build Number

private_lane :smf_super_pipeline_increment_build_number do |options|

  smf_increment_build_number(
      current_build_number: smf_get_build_number_of_app
  )
end

lane :smf_pipeline_increment_build_number do |options|
  smf_super_pipeline_increment_build_number(options)
end


# Create Git Tag

private_lane :smf_super_pipeline_create_git_tag do |options|

  build_variant = options[:build_variant]
  build_number = smf_get_build_number_of_app
  smf_create_git_tag(build_variant: build_variant, build_number: build_number)
end

lane :smf_pipeline_create_git_tag do |options|
  smf_super_pipeline_create_git_tag(options)
end


# Create DMG and run Gatekeeper

private_lane :smf_super_create_dmg_and_gatekeeper do |options|

  build_variant = !options[:build_variant].nil? ? options[:build_variant] : smf_get_first_variant_from_config
  build_variant_config = @smf_fastlane_config[:build_variants][build_variant.to_sym]

  dmg_path = smf_create_dmg_from_app(
      build_variant: build_variant,
      team_id: build_variant_config[:team_id],
      code_signing_identity: build_variant_config[:code_signing_identity]
  )

  should_notarize = smf_config_get(build_variant, :notarize) && smf_is_mac_build(build_variant)

  smf_notarize(
    should_notarize: should_notarize,
    dmg_path: dmg_path,
    bundle_id: build_variant_config[:bundle_identifier],
    username: build_variant_config[:apple_id],
    asc_provider: build_variant_config[:team_id],
    custom_provider: build_variant_config[:notarization_custom_provider]
  )

end

lane :smf_create_dmg_and_gatekeeper do |options|
  smf_super_create_dmg_and_gatekeeper(options)
end


# Upload Dsyms

private_lane :smf_super_upload_dsyms do |options|

  build_variant_config = @smf_fastlane_config[:build_variants][options[:build_variant].to_sym]
  slack_channel = @smf_fastlane_config[:project][:slack_channel]

  smf_upload_to_sentry(
      build_variant: options[:build_variant],
      org_slug: @smf_fastlane_config[:sentry_org_slug],
      project_slug: @smf_fastlane_config[:sentry_project_slug],
      build_variant_org_slug: build_variant_config[:sentry_org_slug],
      build_variant_project_slug: build_variant_config[:sentry_project_slug],
      slack_channel: slack_channel
  )

end

lane :smf_upload_dsyms do |options|
  smf_super_upload_dsyms(options)
end


# Uplaod to Sparkle

private_lane :smf_super_pipeline_upload_with_sparkle do |options|

  build_variant = !options[:build_variant].nil? ? options[:build_variant] : smf_get_first_variant_from_config
  build_variant_config = @smf_fastlane_config[:build_variants][build_variant.to_sym]
  sparkle_config = build_variant_config[:sparkle]

  smf_upload_with_sparkle(
      build_variant: build_variant,
      create_intermediate_folder: sparkle_config[:create_intermediate_folder],
      scheme: build_variant_config[:scheme],
      sparkle_dmg_path: sparkle_config[:dmg_path],
      sparkle_upload_user: sparkle_config[:upload_user],
      sparkle_upload_url: sparkle_config[:upload_url],
      sparkle_version: sparkle_config[:sparkle_version],
      sparkle_signing_team: sparkle_config[:sparkle_signing_team],
      sparkle_xml_name: sparkle_config[:xml_name],
      sparkle_private_key: sparkle_config[:signing_key]
  ) if build_variant_config[:use_sparkle] == true
end

lane :smf_pipeline_upload_with_sparkle do |options|
  smf_super_pipeline_upload_with_sparkle(options)
end


# Upload to AppCenter

private_lane :smf_super_upload_to_appcenter do |options|
  build_variant = options[:build_variant]
  build_variant_config = @smf_fastlane_config[:build_variants][build_variant.to_sym]
  appcenter_app_id = smf_get_appcenter_id(build_variant)
  destinations = build_variant_config[:appcenter_destinations]

  # Upload the IPA to AppCenter
  smf_ios_upload_to_appcenter(
    destinations: smf_get_appcenter_destination_groups(build_variant, destinations),
    build_variant: build_variant,
    build_number: smf_get_build_number_of_app,
    app_id: appcenter_app_id,
    escaped_filename: build_variant_config[:scheme].gsub(' ', "\ "),
    path_to_ipa_or_app: smf_path_to_ipa_or_app,
    is_mac_app: true,
    podspec_path: build_variant_config[:podspec_path],
  ) if !appcenter_app_id.nil?

end

lane :smf_upload_to_appcenter do |options|
  smf_super_upload_to_appcenter(options)
end


# Push Git Tag / Release

private_lane :smf_super_push_git_tag_release do |options|

  local_branch = options[:local_branch]
  build_variant = options[:build_variant]

  changelog = smf_read_changelog

  smf_git_pull(local_branch)
  smf_push_to_git_remote(local_branch: local_branch)

  # Create the GitHub release
  build_number = get_build_number(xcodeproj: "#{@smf_fastlane_config[:project][:project_name]}.xcodeproj")
  smf_create_github_release(
      build_number: build_number,
      tag: smf_get_tag_of_app(build_variant, build_number),
      branch: local_branch,
      build_variant: build_variant,
      changelog: changelog
  )
end

lane :smf_push_git_tag_release do |options|
  smf_super_push_git_tag_release(options)
end


# Send Slack Notification

private_lane :smf_super_send_slack_notification do |options|

  slack_channel = @smf_fastlane_config[:project][:slack_channel]

  smf_send_default_build_success_notification(
      name: smf_get_default_name_of_app(options[:build_variant]),
      slack_channel: slack_channel
  )
end

lane :smf_send_slack_notification do |options|
  smf_super_send_slack_notification(options)
end