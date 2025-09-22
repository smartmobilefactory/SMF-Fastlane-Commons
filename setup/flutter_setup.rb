# Setup Dependencies - pod install & `sh generate.sh` (optional: Phrase App)

private_lane :smf_super_shared_setup_dependencies do |options|

  build_variant = !options[:build_variant].nil? ? options[:build_variant] : smf_get_first_variant_from_config
  build_variant_ios_config = @smf_fastlane_config[:build_variants][build_variant.to_sym][:ios]

  smf_build_precheck(
      upload_itc: build_variant_ios_config[:upload_itc],
      itc_apple_id: build_variant_ios_config[:itc_apple_id]
  )

  sh("cd #{smf_workspace_dir} && #{smf_get_flutter_binary_path} doctor")
  sh("cd #{smf_workspace_dir} && #{smf_get_flutter_binary_path} packages get")
  ENV['CI_FLUTTER_PATH'] = smf_get_flutter_binary_path
  generate_sh_file = "#{smf_workspace_dir}/generate.sh"
  if File.exist?(generate_sh_file)
    sh("cd #{smf_workspace_dir}; sh generate.sh")
  end
end

lane :smf_shared_setup_dependencies_pr_check do |options|
  smf_super_shared_setup_dependencies(options)
end

lane :smf_setup_dependencies_build do |options|
  smf_super_shared_setup_dependencies(options)
end


# Update Jenkinsfile

private_lane :smf_shared_super_generate_files do |options|
  smf_update_generated_files
end

lane :smf_shared_generate_files do |options|
  smf_shared_super_generate_files(options)
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


# Build

private_lane :smf_super_ios_build do |options|
  build_variant = !options[:build_variant].nil? ? options[:build_variant] : smf_get_first_variant_from_config
  build_variant_config = @smf_fastlane_config[:build_variants][build_variant.to_sym]
  build_variant_ios_config = @smf_fastlane_config[:build_variants][build_variant.to_sym][:ios]

  sh("cd #{smf_workspace_dir} && #{smf_get_flutter_binary_path} build ios --release --no-codesign --flavor #{build_variant}")

  # If force match was passed as option from jenkins (e.g. manually enabled for the build)
  # then use it, if its nil or false the value from the config json is used
  force_match = options[:force_match]
  force_match ||= smf_config_get(build_variant, :match, :force)

  smf_download_provisioning_profiles(
      team_id: build_variant_ios_config[:team_id],
      apple_id: build_variant_ios_config[:apple_id],
      use_wildcard_signing: build_variant_ios_config[:use_wildcard_signing],
      bundle_identifier: build_variant_ios_config[:bundle_identifier],
      use_default_match_config: build_variant_ios_config[:match].nil?,
      match_read_only: build_variant_ios_config.dig(:match, :read_only),
      match_type: build_variant_ios_config.dig(:match, :type),
      # template_name: build_variant_ios_config.dig(:match, :template_name), # Removed due to Apple API deprecation
      extensions_suffixes: !build_variant_config[:extensions_suffixes].nil? ? build_variant_config[:extensions_suffixes] : @smf_fastlane_config[:extensions_suffixes],
      build_variant: build_variant,
      force: force_match
  )
  smf_build_apple_app(
      skip_export: options[:skip_export].nil? ? false : options[:skip_export],
      scheme: build_variant_config[:flavor],
      should_clean_project: build_variant_ios_config[:should_clean_project],
      required_xcode_version: @smf_fastlane_config[:project][:xcode_version],
      project_name: @smf_fastlane_config[:project][:project_name],
      xcconfig_name: smf_get_xcconfig_name(build_variant.to_sym),
      code_signing_identity: build_variant_ios_config[:code_signing_identity],
      upload_itc: build_variant_ios_config[:upload_itc].nil? ? false : build_variant_ios_config[:upload_itc],
      upload_bitcode: build_variant_ios_config[:upload_bitcode].nil? ? true : build_variant_ios_config[:upload_bitcode],
      export_method: build_variant_ios_config[:export_method],
      icloud_environment: smf_get_icloud_environment(build_variant.to_sym),
      workspace: "#{smf_workspace_dir}/ios/Runner.xcworkspace"
  )
end

lane :smf_ios_build do |options|
  smf_super_ios_build(options)
end

private_lane :smf_super_android_build do |options|

  build_variant = !options[:build_variant].nil? ? options[:build_variant] : smf_get_first_variant_from_config
  build_variant_android_config = @smf_fastlane_config[:build_variants][build_variant.to_sym][:android]

  keystore_folder = build_variant_android_config[:keystore]

  if keystore_folder.nil?
    sh("cd #{smf_workspace_dir} && #{smf_get_flutter_binary_path} build apk --release --flavor #{build_variant}")
  else
    keystore_values = smf_pull_keystore(folder: keystore_folder)
    ENV["keystore_file"] = keystore_values[:keystore_file]
    ENV["keystore_password"] = keystore_values[:keystore_password]
    ENV["keystore_key_alias"] = keystore_values[:keystore_key_alias]
    ENV["keystore_key_password"] = keystore_values[:keystore_key_password]

    # build apk for internal testing and aab for play store distribution
    sh("cd #{smf_workspace_dir} && #{smf_get_flutter_binary_path} build apk --release --flavor #{build_variant}")
    sh("cd #{smf_workspace_dir} && #{smf_get_flutter_binary_path} build appbundle --release --flavor #{build_variant}")
  end

end

lane :smf_android_build do |options|
  smf_super_android_build(options)
end


# Generate Changelog

private_lane :smf_super_generate_changelog do |options|

  build_variant = options[:build_variant]

  smf_git_changelog(build_variant: build_variant)
end

lane :smf_generate_changelog do |options|
  smf_super_generate_changelog(options)
end


# Upload Dsyms

private_lane :smf_super_upload_dsyms do |options|

  build_variant = options[:build_variant]
  build_variant_config = @smf_fastlane_config[:build_variants][build_variant.to_sym]
  project_config = @smf_fastlane_config[:project]
  build_variant_ios_config = @smf_fastlane_config[:build_variants][build_variant.to_sym][:ios]

  smf_upload_to_sentry(
      build_variant: build_variant,
      org_slug: project_config[:sentry_org_slug],
      project_slug: project_config[:sentry_project_slug],
      escaped_filename: build_variant_config[:flavor].gsub(' ', "\ "),
      build_variant_org_slug: build_variant_ios_config[:sentry_org_slug],
      build_variant_project_slug: build_variant_ios_config[:sentry_project_slug]
  )

end

lane :smf_upload_dsyms do |options|
  smf_super_upload_dsyms(options)
end


# Upload to AppCenter (Deprecated - AppCenter service discontinued)
# This functionality has been removed as AppCenter is no longer available

# Upload to iTunes

private_lane :smf_super_upload_to_itunes do |options|

  build_variant = options[:build_variant]
  build_variant_ios_config = @smf_fastlane_config[:build_variants][build_variant.to_sym][:ios]

  smf_upload_to_testflight(
      build_variant: build_variant,
      apple_id: build_variant_ios_config[:apple_id],
      itc_team_id: build_variant_ios_config[:itc_team_id],
      itc_apple_id: build_variant_ios_config[:itc_apple_id],
      skip_waiting_for_build_processing: build_variant_ios_config[:itc_skip_waiting].nil? ? false : build_variant_ios_config[:itc_skip_waiting],
      slack_channel: @smf_fastlane_config[:slack_channel],
      bundle_identifier: build_variant_ios_config[:bundle_identifier],
      upload_itc: build_variant_ios_config[:upload_itc],
      required_xcode_version: @smf_fastlane_config[:project][:xcode_version],
      itc_platform: build_variant_ios_config[:itc_platform]
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

  build_number = smf_get_build_number_of_app
  # Create the GitHub release
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

  build_variant = options[:build_variant]
  slack_channel = @smf_fastlane_config[:project][:slack_channel]

  smf_send_default_build_success_notification(
      name: smf_get_default_name_and_version(build_variant),
      slack_channel: slack_channel
  )
end

lane :smf_send_slack_notification do |options|
  smf_super_send_slack_notification(options)
end


# Run Unit Tests

private_lane :smf_super_run_unit_tests do |options|
  sh("cd #{smf_workspace_dir} && #{smf_get_flutter_binary_path} test")
end

lane :smf_run_unit_tests do |options|
  smf_super_run_unit_tests(options)
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


# Linter

private_lane :smf_super_linter do |options|
  smf_run_flutter_analyzer(options)
end

lane :smf_linter do |options|
  smf_super_linter(options)
end


# Danger

private_lane :smf_super_shared_pipeline_danger do |options|

  smf_danger
end

lane :smf_shared_pipeline_danger do |options|
  smf_super_shared_pipeline_danger(options)
end

