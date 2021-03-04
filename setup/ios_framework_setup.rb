
# Import ios_setup_file for normal app builds

ios_setup_file = "#{@fastlane_commons_dir_path}/setup/ios_setup.rb"

if File.exist?(ios_setup_file)
  import(ios_setup_file)
else
  raise "Can't find ios_setup file at #{ios_setup_file}"
end

######### PULLREQUEST CHECK LANES ##########

# Update File

private_lane :smf_pod_super_generate_files do |options|

  ios_build_nodes = smf_string_array_to_array(ENV['SMF_IOS_BUILD_NODES'])

  smf_update_generated_files(
    ios_build_nodes: ios_build_nodes
  )
end

lane :smf_pod_generate_files do |options|
  smf_super_generate_files(options)
end


# Setup dependencies

private_lane :smf_pod_super_setup_dependencies_pr_check do |options|

  podspecs = [@smf_fastlane_config[:build_variants][:framework][:podspec_path]]
  additional_podspecs = @smf_fastlane_config[:build_variants][:framework][:additional_podspecs]
  podspecs += additional_podspecs unless additional_podspecs.nil?

  smf_build_precheck(
    pods_spec_repo: @smf_fastlane_config[:build_variants][:framework][:pods_specs_repo],
    podspecs: podspecs
  )

  smf_pod_install
end

lane :smf_pod_setup_dependencies_pr_check do |options|
  smf_pod_super_setup_dependencies_pr_check(options)
end

override_lane :smf_setup_dependencies_reporting do |options|
  smf_pod_super_setup_dependencies_pr_check(options)
end

# Lint podspecs
# This assures that if there are multiple podspecs, that they all build properly

private_lane :smf_super_lint_podspecs do |options|

  main_podspec = @smf_fastlane_config[:build_variants][:framework][:podspec_path]

  required_xcode_version = @smf_fastlane_config[:project][:xcode_version]

  smf_lint_podspecs(
    required_xcode_version: required_xcode_version
  )
end

lane :smf_pod_lint_podspecs do |options|
  smf_super_lint_podspecs(options)
end

# Run Unit Tests

private_lane :smf_pod_super_unit_tests do |options|

  build_variants_for_pr_check = smf_build_variants_for_pod_pr_check(options)
  build_variants_for_pr_check.each { |variant|

    build_variant_config = @smf_fastlane_config[:build_variants][variant.to_sym]
    testing_for_mac = build_variant_config[:platform] == 'mac'

    if build_variant_config[:download_provisioning_profiles] != false

      UI.message("Downloading provisioning profiles for variant '#{variant}'")

      smf_download_provisioning_profiles(
          team_id: build_variant_config[:team_id],
          apple_id: build_variant_config[:apple_id],
          use_wildcard_signing: build_variant_config[:use_wildcard_signing],
          bundle_identifier: build_variant_config[:bundle_identifier],
          use_default_match_config: build_variant_config[:match].nil?,
          match_read_only: build_variant_config.dig(:match, :read_only),
          match_type: build_variant_config.dig(:match,:type),
          template_name: build_variant_config.dig(:match, :template_name),
          extensions_suffixes: !build_variant_config[:extensions_suffixes].nil? ? build_variant_config[:extensions_suffixes] : @smf_fastlane_config[:extensions_suffixes],
          build_variant: variant,
          force: build_variant_config.dig(:match, :force),
          platform: smf_config_get(build_variant, :match, :platform)
      )
    end

    UI.message("Running unit tests for variant '#{variant}' for PR Check")

    smf_ios_unit_tests(
        project_name: @smf_fastlane_config[:project][:project_name],
        unit_test_scheme: build_variant_config[:unit_test_scheme],
        scheme: build_variant_config[:scheme],
        unit_test_xcconfig_name: !build_variant_config[:xcconfig_name].nil? ? build_variant_config[:xcconfig_name][:unittests] : nil,
        device: build_variant_config["tests.device_to_test_against".to_sym],
        required_xcode_version: @smf_fastlane_config[:project][:xcode_version],
        testing_for_mac: testing_for_mac
    )
  }
end

lane :smf_pod_unit_tests do |options|
  smf_pod_super_unit_tests(options)
end

override_lane :smf_unit_tests_reporting do |options|
  smf_pod_super_unit_tests(options)
end

# Linter

private_lane :smf_pod_super_linter do
  smf_run_swift_lint
end

lane :smf_pod_linter do
  smf_pod_super_linter
end


# Danger

private_lane :smf_pod_super_danger do |options|

  build_variant_config = @smf_fastlane_config[:build_variants][:framework]

  podspec_path = build_variant_config[:podspec_path]
  bump_type = smf_extract_bump_type_from_pr_body

  smf_danger(
    podspec_path: podspec_path,
    bump_type: bump_type
  )
end

lane :smf_pod_danger do |options|
  smf_pod_super_danger(options)
end

############ AUTOMATIC REPORTING LANES ############
###########  For Unit-Tests Reporting  ############

override_lane :smf_automatic_reporting do |options|
  smf_ios_monitor_unit_tests(options)
end

############ META REPORTING LANES ############

private_lane :smf_super_pod_meta_reporting do |options|
  build_variant = smf_build_variant(options)
  smf_pod_linter
  smf_report_metrics(build_variant: build_variant, smf_get_meta_db_project_name: smf_get_meta_db_project_name)
end

lane :smf_pod_meta_reporting do |options|
  smf_super_pod_meta_reporting(options)
end

############ POD PUBLISH LANES ############

# Setup Workspace

private_lane :smf_super_pod_setup_workspace_for_publishing do |options|
  options[:build_variant] = 'framework'
  smf_setup_workspace(options)
end

lane :smf_pod_setup_workspace_for_publishing do |options|
  smf_super_pod_setup_workspace_for_publishing(options)
end


# Generate Changelog

private_lane :smf_super_pod_generate_changelog do |options|
  smf_git_changelog(is_library: true)
end

lane :smf_pod_generate_changelog do |options|
  smf_super_pod_generate_changelog(options)
end


# Increment Version Number

private_lane :smf_super_pipeline_increment_version_number do |options|

  bump_type = options[:build_variant]
  build_variant_config = @smf_fastlane_config[:build_variants][:framework]
  podspec_path = build_variant_config[:podspec_path]
  additional_podspecs = build_variant_config[:additional_podspecs]

  smf_increment_version_number(
      podspec_path: podspec_path,
      bump_type: bump_type,
      additional_podspecs: additional_podspecs
  )
end

lane :smf_pipeline_increment_version_number do |options|
  smf_super_pipeline_increment_version_number(options)
end


# Release Pod

private_lane :smf_super_release_pod do |options|

  build_variant_config = @smf_fastlane_config[:build_variants][:framework]
  podspec_path = build_variant_config[:podspec_path]
  xcode_version = @smf_fastlane_config[:project][:xcode_version]
  specs_repo = build_variant_config[:pods_specs_repo]
  additional_podspecs = build_variant_config[:additional_podspecs].nil? ? [] : build_variant_config[:additional_podspecs]
  local_branch = options[:local_branch]

  smf_git_pull(local_branch)

  smf_push_pod(
    podspec_path: podspec_path,
    specs_repo: specs_repo,
    required_xcode_version: xcode_version,
    local_branch: local_branch
  )

  additional_podspecs.each do |additional_podspec_path|
    UI.message("Pushing pod with podspec: #{additional_podspec_path}")

    smf_git_pull(local_branch)

    smf_push_pod(
      podspec_path: additional_podspec_path,
      specs_repo: specs_repo,
      required_xcode_version: xcode_version,
      local_branch: local_branch
    )
  end

  changelog = smf_read_changelog

  # Create the GitHub release
  smf_create_github_release(
      tag: smf_get_tag_of_pod(podspec_path),
      branch: local_branch,
      build_variant: 'framework',
      changelog: changelog,
      podspec_path: podspec_path
  )

end

lane :smf_release_pod do |options|
  smf_super_release_pod(options)
end


# Send Slack Notification

private_lane :smf_super_pod_send_slack_notification do |options|

  slack_channel = @smf_fastlane_config[:project][:slack_channel]

  smf_send_default_build_success_notification(
      name: smf_get_default_name_of_pod('framework'),
      slack_channel: slack_channel
  )
end

lane :smf_pod_send_slack_notification do |options|
  smf_super_pod_send_slack_notification(options)
end


