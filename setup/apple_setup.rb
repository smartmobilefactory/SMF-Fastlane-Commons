########## PULLREQUEST CHECK LANES ##########

# Update Files

private_lane :smf_super_generate_files do |options|

  ios_build_nodes = smf_string_array_to_array(ENV['SMF_IOS_BUILD_NODES'])

  smf_update_generated_files(
    ios_build_nodes: ios_build_nodes
  )
end

lane :smf_generate_files do |options|
  smf_super_generate_files(options)
end


# Setup Dependencies

private_lane :smf_super_setup_dependencies do |options|

  build_variant = smf_build_variant(options)

  smf_build_precheck(
    upload_itc: smf_config_get(build_variant, :upload_itc),
    itc_apple_id: smf_config_get(build_variant, :itc_apple_id)
  )

  smf_pod_install
end

lane :smf_setup_dependencies_pr_check do |options|
  smf_super_setup_dependencies(options)
end

lane :smf_setup_dependencies_reporting do |options|
  smf_super_setup_dependencies(options)
end

lane :smf_setup_dependencies_build do |options|
  smf_super_setup_dependencies(options)
end


# Build

private_lane :smf_super_build do |options|

  build_variant = smf_build_variant(options)

  extension_suffixes = smf_config_get(build_variant, :extensions_suffixes)
  extension_suffixes = smf_config_get(nil, :extensions_suffixes) if extension_suffixes.nil?

  default_platform = smf_is_mac_build(build_variant) ? 'macos' : 'ios'
  match_platform = smf_config_get(build_variant, :match, :platform)
  platform = match_platform.nil? ? default_platform : match_platform

  if options[:skip_match] == false
    # If force match was passed as option from jenkins (e.g. manually enabled for the build)
    # then use it, if its nil or false the value from the config json is used
    force_match = options[:force_match]
    force_match ||= smf_config_get(build_variant, :match, :force)

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
      force: force_match,
      platform: platform
    )
  end

  smf_build_apple_app(
    build_variant: build_variant,
    skip_export: options[:skip_export],
    skip_package_pkg: smf_config_get(build_variant,:skip_package_pkg),
    skip_package_ipa: smf_config_get(build_variant, :skip_package_ipa),
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
  testing_for_mac = smf_is_mac_build(build_variant)
  use_thread_sanitizer = !(smf_config_get(nil, :project, :skip_thread_sanitizer_for_unit_tests) == true)
  
  smf_ios_unit_tests(
    project_name: smf_config_get(nil, :project, :project_name),
    unit_test_scheme: smf_config_get(build_variant, :unit_test_scheme),
    scheme: smf_config_get(build_variant, :scheme),
    unit_test_xcconfig_name: smf_config_get(build_variant, :xcconfig_name, :unittests),
    device: smf_config_get(build_variant, 'tests.device_to_test_against'.to_sym),
    required_xcode_version: smf_config_get(nil, :project, :xcode_version),
    testing_for_mac: testing_for_mac,
    use_thread_sanitizer: use_thread_sanitizer
  )

end

lane :smf_unit_tests do |options|
  smf_super_unit_tests(options)
end

lane :smf_unit_tests_reporting do |options|
  smf_super_unit_tests(options)
end

# Reporting

lane :smf_automatic_reporting do |options|
  smf_ios_monitor_unit_tests(options)
end

# Linter

private_lane :smf_super_linter do |options|

  required_xcode_version = smf_config_get(nil, :project, :xcode_version)
  smf_run_swift_lint(required_xcode_version: required_xcode_version)
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
  smf_linter(options)
  smf_report_metrics(build_variant: build_variant, smf_get_meta_db_project_name: smf_get_meta_db_project_name)
end

lane :smf_report do |options|
  # smf_super_report(options)
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
    current_build_number: smf_get_build_number_of_app,
    skip_build_nr_update_in_plists: smf_config_get(nil, :project, :skip_build_nr_update_in_plists)
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

# Create DMG and run Gatekeeper

private_lane :smf_super_create_dmg_and_gatekeeper do |options|

  build_variant = smf_build_variant(options)

  unless smf_is_mac_build(build_variant)
    UI.message("Skipping lane for platform #{@platform} and build variant #{build_variant}")
    next
  end

  # The `dmg_template_path` key can be at the project level or at the build_variant level. The build_variant level overrides the project one.
  # If nothing is found, no template will be used for the DMG creation
  dmg_template_path = smf_config_get(build_variant, :dmg_template_path) 
  dmg_template_path = smf_config_get(nil, :project, :dmg_template_path) unless !dmg_template_path.nil?
  # Then we make it a proper path
  dmg_template_path = "#{smf_workspace_dir}/#{dmg_template_path}" unless dmg_template_path.nil?

  dmg_path = smf_create_dmg_from_app(
    team_id: smf_config_get(build_variant, :team_id),
    code_signing_identity: smf_config_get(build_variant, :code_signing_identity),
    dmg_template_path: dmg_template_path
  )

  should_notarize = smf_config_get(build_variant, :notarize) && smf_is_mac_build(build_variant)

  smf_notarize(
    should_notarize: should_notarize,
    dmg_path: dmg_path,
    bundle_id: smf_config_get(build_variant, :bundle_identifier),
    username: smf_config_get(build_variant, :apple_id),
    asc_provider: smf_config_get(build_variant, :team_id),
    custom_provider: smf_config_get(build_variant, :notarization_custom_provider)
  )

end

lane :smf_create_dmg_and_gatekeeper do |options|
  smf_super_create_dmg_and_gatekeeper(options)
end


# Upload Dsyms

private_lane :smf_super_upload_dsyms do |options|
  build_variant = smf_build_variant(options)

  smf_upload_to_sentry(
    build_variant: build_variant,
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

# Upload to Sparkle

private_lane :smf_super_pipeline_upload_with_sparkle do |options|

  build_variant = smf_build_variant(options)

  unless smf_is_mac_build(build_variant)
    UI.message("Skipping lane for platform #{@platform} and build variant #{build_variant}")
    next
  end

  if smf_config_get(build_variant, :use_sparkle) == true
    smf_upload_with_sparkle(
      build_variant: build_variant,
      create_intermediate_folder: smf_config_get(build_variant, :sparkle, :create_intermediate_folder),
      scheme: smf_config_get(build_variant, :scheme),
      sparkle_dmg_path: smf_config_get(build_variant, :sparkle, :dmg_path),
      sparkle_upload_user: smf_config_get(build_variant, :sparkle, :upload_user),
      sparkle_upload_url: smf_config_get(build_variant, :sparkle, :upload_url),
      sparkle_version: smf_config_get(build_variant, :sparkle, :sparkle_version),
      sparkle_signing_team: smf_config_get(build_variant, :sparkle, :sparkle_signing_team),
      sparkle_xml_name: smf_config_get(build_variant, :sparkle, :xml_name),
      sparkle_private_key: smf_config_get(build_variant, :sparkle, :signing_key)
    )
  end
end

lane :smf_pipeline_upload_with_sparkle do |options|
  smf_super_pipeline_upload_with_sparkle(options)
end


# Upload to AppCenter

private_lane :smf_super_upload_to_appcenter do |options|
  build_variant = smf_build_variant(options)

  appcenter_app_id = smf_get_appcenter_id(build_variant)
  destinations = smf_config_get(build_variant, :appcenter_destinations)

  # Upload the IPA to AppCenter
  smf_ios_upload_to_appcenter(
    destinations: smf_get_appcenter_destination_groups(build_variant, destinations),
    build_variant: build_variant,
    build_number: smf_get_build_number_of_app,
    app_id: appcenter_app_id,
    escaped_filename: smf_config_get(build_variant, :scheme).gsub(' ', "\ "),
    path_to_ipa_or_app: smf_path_to_ipa_or_app,
    is_mac_app: smf_is_mac_build(build_variant),
    podspec_path: smf_config_get(build_variant, :podspec_path)
  ) unless appcenter_app_id.nil?
end

lane :smf_upload_to_appcenter do |options|
  smf_super_upload_to_appcenter(options)
end


#Upload to Firebase
private_lane :smf_super_upload_to_firebase do |options|

  build_variant = smf_build_variant(options)
  
  service_credentials_file = ENV['FIREBASE_CREDENTIALS']

  firebase_app_id = smf_get_firebase_id(build_variant)
  destinations = smf_config_get(build_variant, :firebase_destinations) || "RWC"


  if service_credentials_file.nil?
    UI.message("Skipping upload to Firebase because Firebase credentials are missing.")
    return
  end

  if firebase_app_id.nil?
    UI.message("Skipping upload to Firebase because Firebase app id is missing.")
    return
  end

  smf_ios_upload_to_firebase(
    build_variant: build_variant,
    app_id: firebase_app_id,
    destinations: destinations,
    escaped_filename: smf_config_get(build_variant, :scheme).gsub(' ', "\ "),
    path_to_ipa_or_app: smf_path_to_ipa_or_app
  )
end

lane :smf_upload_to_firebase do |options|
  smf_super_upload_to_firebase(options)
end

# Upload to iTunes

private_lane :smf_super_upload_to_itunes do |options|
  build_variant = smf_build_variant(options)

  slack_channel = smf_config_get(nil, :project, :slack_channel)
  xcode_version = smf_config_get(nil, :project, :xcode_version)

  smf_upload_to_testflight(
    build_variant: build_variant,
    apple_id: smf_config_get(build_variant, :apple_id),
    itc_team_id: smf_config_get(build_variant, :itc_team_id),
    itc_apple_id: smf_config_get(build_variant, :itc_apple_id),
    skip_waiting_for_build_processing: smf_config_get(build_variant, :itc_skip_waiting),
    slack_channel: slack_channel,
    bundle_identifier: smf_config_get(build_variant, :bundle_identifier),
    upload_itc: smf_config_get(build_variant, :upload_itc),
    required_xcode_version: xcode_version,
    itc_platform: smf_config_get(build_variant, :itc_platform)
  )
end

lane :smf_upload_to_itunes do |options|
  smf_super_upload_to_itunes(options)
end


# Push Git Tag / Release

private_lane :smf_super_push_git_tag_release do |options|

  local_branch = options[:local_branch]
  build_variant = smf_build_variant(options)

  changelog = smf_read_changelog

  smf_git_pull(local_branch)
  smf_push_to_git_remote(local_branch: local_branch)

  # Create the GitHub release
  build_number = get_build_number(xcodeproj: smf_get_xcodeproj_file_name)
  smf_create_github_release(
    build_number: build_number,
    tag: smf_get_tag_of_app(build_variant, build_number),
    branch: local_branch,
    build_variant: build_variant,
    changelog: changelog
  )

  smf_make_jira_realease_comment(
    build_variant: build_variant
  )
end

lane :smf_push_git_tag_release do |options|
  smf_super_push_git_tag_release(options)
end


# Send Slack Notification

private_lane :smf_super_send_slack_notification do |options|

  build_variant = smf_build_variant(options)
  slack_channel = smf_config_get(nil, :project, :slack_channel)

  smf_send_default_build_success_notification(
    name: smf_get_default_name_and_version(build_variant),
    slack_channel: slack_channel
  )
end

lane :smf_send_slack_notification do |options|
  smf_super_send_slack_notification(options)
end
