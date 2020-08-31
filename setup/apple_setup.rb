########## PULLREQUEST CHECK LANES ##########

# Update Files

private_lane :smf_super_generate_files do
  smf_update_generated_files
end

lane :smf_generate_files do
  smf_super_generate_files
end


# Setup Dependencies

private_lane :smf_super_setup_dependencies do |options|

  build_variant = smf_build_variant(options)

  smf_build_precheck(
    upload_itc: smf_config_get(build_variant, :upload_itc),
    itc_apple_id: smf_config_get(build_variant, :itc_apple_id)
  )

  smf_pod_install

  # Called only when upload_itc is set to true. This way the
  # build will fail in the beginning if there are any problems
  # with itc. Saves time.
  smf_verify_itc_upload_errors(
    build_variant: build_variant,
    upload_itc: smf_config_get(build_variant, :upload_itc),
    project_name: smf_config_get(nil, :project_name),
    itc_skip_version_check: smf_config_get(build_variant, :itc_skip_version_check),
    username: smf_config_get(build_variant, :itc_apple_id),
    itc_team_id: smf_config_get(build_variant, :itc_team_id),
    bundle_identifier: smf_config_get(build_variant, :bundle_identifier)
  )
end

lane :smf_setup_dependencies_pr_check do |options|
  smf_super_setup_dependencies(options)
end

lane :smf_setup_dependencies_build do |options|
  smf_super_setup_dependencies(options)
end


# Build

private_lane :smf_super_build do |options|

  build_variant = smf_build_variant(options)

  extension_suffixes = smf_config_get(build_variant, :extensions_suffixes)
  extension_suffixes = smf_config_get(nil , :extensions_suffixes) if extension_suffixes.nil?

  smf_download_provisioning_profiles(
    team_id: smf_config_get(build_variant, :team_id),
    apple_id: smf_config_get(build_variant, :apple_id),
    use_wildcard_signing: smf_config_get(build_variant, :use_wildcard_signing),
    bundle_identifier: smf_config_get(build_variant, :bundle_identifier),
    use_default_match_config: smf_config_get(build_variant, :match).nil?,
    match_read_only: smf_config_get(build_variant, :match, :read_only),
    match_type: smf_config_get(build_variant, :match, :type),
    template_name: smf_config_get(build_variant, :match, :template_name),
    extensions_suffixes: extension_suffixes,
    build_variant: build_variant,
    force: smf_config_get(build_variant, :match, :force)
  )

  skip_export = options[:skip_export].nil? ? false : options[:skip_export]

  smf_build_ios_app(
    skip_export: skip_export,
    scheme: smf_config_get(build_variant, :scheme),
    should_clean_project: smf_config_get(build_variant, :should_clean_project),
    required_xcode_version: smf_config_get(nil, :project, :xcode_version),
    project_name: smf_config_get(nil, :project, :project_name),
    xcconfig_name: smf_get_xcconfig_name(build_variant.to_sym),
    code_signing_identity: smf_config_get(build_variant, :code_signing_identity),
    upload_itc: smf_config_get(build_variant, :upload_itc),
    upload_bitcode: smf_config_get(build_variant, :upload_bitcode),
    export_method: smf_config_get(build_variant, :export_method),
    icloud_environment: smf_get_icloud_environment(build_variant.to_sym)
  )
end

lane :smf_build do |options|
  smf_super_build(options)
end


# Unit-Tests

private_lane :smf_super_unit_tests do |options|

  build_variant = smf_build_variant(options)
  testing_for_mac = smf_is_catalyst_mac_build(options)

  smf_ios_unit_tests(
    project_name: smf_config_get(nil, :project, :project_name),
    unit_test_scheme: smf_config_get(build_variant, :unit_test_scheme),
    scheme: smf_config_get(build_variant, :scheme),
    unit_test_xcconfig_name: smf_config_get(build_variant, :xcconfig_name, :unittests),
    device: smf_config_get(build_variant, 'tests.device_to_test_against'.to_sym),
    required_xcode_version: smf_config_get(build_variant, :project, :xcode_version),
    testing_for_mac: testing_for_mac
  )

end

lane :smf_unit_tests do |options|
  smf_super_unit_tests(options)
end


# Linter

private_lane :smf_super_linter do |options|
  smf_run_swift_lint(options)
end

lane :smf_linter do |options|
  smf_super_linter(options)
end


# Danger

private_lane :smf_super_pipeline_danger do |options|
  smf_danger(options)
end

lane :smf_pipeline_danger do |options|
  smf_super_pipeline_danger(options)
end

# Report project data

private_lane :smf_super_report do |options|
  build_variant = smf_build_variant(options)
  smf_report_metrics(build_variant: build_variant, smf_get_meta_db_project_name: smf_get_meta_db_project_name)
end

lane :smf_report do |options|
  smf_super_report(options)
end

########## ADDITIONAL LANES USED FOR BUILDING ##########

# Generate Changelog

private_lane :smf_super_generate_changelog do |options|
  build_variant = smf_build_variant(options)
  smf_git_changelog(build_variant: build_variant)
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

  build_variant = smf_build_variant(options)
  build_number = smf_get_build_number_of_app
  smf_create_git_tag(
    build_variant: build_variant,
    build_number: build_number
  )
end

lane :smf_pipeline_create_git_tag do |options|
  smf_super_pipeline_create_git_tag(options)
end


# Upload Dsyms

private_lane :smf_super_upload_dsyms do |options|
  build_variant = smf_build_variant(options)

  smf_upload_to_sentry(
    build_variant: build_variant[:build_variant],
    org_slug: smf_config_get(nil, :project, :sentry_org_slug),
    project_slug: smf_config_get(nil, :project, :sentry_project_slug),
    build_variant_org_slug: smf_config_get(build_variant, :sentry_org_slug),
    build_variant_project_slug: smf_config_get(build_variant, :sentry_project_slug),
    escaped_filename: smf_config_get(build_variant, :scheme).gsub(' ', "\ "),
    slack_channel: smf_config_get(nil, :project, :slack_channel)
  )

end

lane :smf_upload_dsyms do |options|
  smf_super_upload_dsyms(options)
end


# Upload to AppCenter

private_lane :smf_super_upload_to_appcenter do |options|
  build_variant = smf_build_variant(options)

  appcenter_app_id = smf_get_appcenter_id(build_variant)
  destinations = build_variant_config[:appcenter_destinations]

  # Upload the IPA to AppCenter
  smf_ios_upload_to_appcenter(
    destinations: smf_get_appcenter_destination_groups(build_variant, destinations),
    app_id: appcenter_app_id,
    escaped_filename: smf_config_get(build_variant, :scheme).gsub(' ', "\ "),
    path_to_ipa_or_app: smf_path_to_ipa_or_app
  ) if !appcenter_app_id.nil?
end

lane :smf_upload_to_appcenter do |options|
  smf_super_upload_to_appcenter(options)
end


# Upload to iTunes

private_lane :smf_super_upload_to_itunes do |options|

  build_variant_config = @smf_fastlane_config[:build_variants][options[:build_variant].to_sym]
  slack_channel = @smf_fastlane_config[:project][:slack_channel]

  smf_upload_to_testflight(
    build_variant: options[:build_variant],
    apple_id: build_variant_config[:apple_id],
    itc_team_id: build_variant_config[:itc_team_id],
    itc_apple_id: build_variant_config[:itc_apple_id],
    skip_waiting_for_build_processing: build_variant_config[:itc_skip_waiting].nil? ? false : build_variant_config[:itc_skip_waiting],
    slack_channel: slack_channel,
    bundle_identifier: build_variant_config[:bundle_identifier],
    upload_itc: build_variant_config[:upload_itc],
    required_xcode_version: @smf_fastlane_config[:project][:xcode_version]
  )
end

lane :smf_upload_to_itunes do |options|
  smf_super_upload_to_itunes(options)
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

  build_variant = options[:build_variant]
  slack_channel = @smf_fastlane_config[:project][:slack_channel]

  smf_send_default_build_success_notification(
    name: smf_get_default_name_of_app(build_variant),
    slack_channel: slack_channel
  )
end

lane :smf_send_slack_notification do |options|
  smf_super_send_slack_notification(options)
end
