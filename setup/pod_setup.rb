ios_setup_file = "#{@fastlane_commons_dir_path}/setup/ios_setup.rb"

if File.exist?(ios_setup_file)
  import(ios_setup_file)
else
  raise "Can't find ios_setup file at #{ios_setup_file}"
end


# Build (Build to Release)

private_lane :smf_super_build_for_pod_pr_check do |options|

  build_variants_for_pr_check = smf_build_variants_for_pod_pr_check
  build_variants_for_pr_check.each { |variant|
    UI.message("Building variant '#{variant}' for PR Check")
    options[:build_variant] = variant
    smf_build(options)
  }
end

lane :smf_build_for_pod_pr_check do |options|
  smf_super_build_for_pod_pr_check(options)
end


# Run Unit Tests

private_lane :smf_super_unit_tests_for_pod_pr_check do |options|

  build_variants_for_pr_check = smf_build_variants_for_pod_pr_check
  build_variants_for_pr_check.each { |variant|

    build_variant_config = @smf_fastlane_config[:build_variants][variant.to_sym]

    UI.message("Downloading provisioning profiles for variant '#{variant}'")

    smf_download_provisioning_profiles(
        team_id: build_variant_config[:team_id],
        apple_id: build_variant_config[:apple_id],
        use_wildcard_signing: build_variant_config[:use_wildcard_signing],
        bundle_identifier: build_variant_config[:bundle_identifier],
        use_default_match_config: build_variant_config[:match].nil?,
        match_read_only: build_variant_config[:match].nil? ? nil : build_variant_config[:match][:read_only],
        match_type: build_variant_config[:match].nil? ? nil : build_variant_config[:match][:type],
        extensions_suffixes: @smf_fastlane_config[:extensions_suffixes],
        build_variant: variant
    )

    UI.message("Running unit tests for variant '#{variant}' for PR Check")
    options[:build_variant] = variant
    smf_unit_tests(options)
  }
end

lane :smf_unit_tests_for_pod_pr_check do |options|
  smf_super_unit_tests_for_pod_pr_check(options)
end


# Linter

private_lane :smf_super_linter_for_pod_pr_check do |options|

  build_variants_for_pr_check = smf_build_variants_for_pod_pr_check
  build_variants_for_pr_check.each { |variant|
    UI.message("Running unit tests for variant '#{variant}' for PR Check")
    options[:build_variant] = variant
    smf_linter(options)
  }
end

lane :smf_linter_for_pod_pr_check do |options|
  smf_super_linter_for_pod_pr_check(options)
end


# Danger

private_lane :smf_super_danger_for_pod_pr_check do |options|

  build_variants_for_pr_check = smf_build_variants_for_pod_pr_check
  build_variants_for_pr_check.each { |variant|
    UI.message("Running unit tests for variant '#{variant}' for PR Check")
    options[:build_variant] = variant
    smf_pipeline_danger(options)
  }
end

lane :smf_danger_for_pod_pr_check do |options|
  smf_super_danger_for_pod_pr_check(options)
end


# Increment Version Number

private_lane :smf_super_pipeline_increment_version_number do |options|

  build_variant = options[:build_variant]
  build_variant_config = @smf_fastlane_config[:build_variants][:framework]

  smf_increment_version_number(
      podspec_path: build_variant_config[:podspec_path],
      bump_type: build_variant
  )
end

lane :smf_pipeline_increment_version_number do |options|
  smf_super_pipeline_increment_version_number(options)
end


# Generate Changelog

private_lane :smf_super_pod_generate_changelog do |options|
  smf_git_changelog(is_library: true)
end

lane :smf_pod_generate_changelog do |options|
  smf_super_pod_generate_changelog(options)
end


# Send Slack Notification

private_lane :smf_super_pod_send_slack_notification do |options|

  slack_channel = @smf_fastlane_config[:project][:slack_channel]

  smf_send_default_build_success_notification(
      name: smf_get_default_name_of_pod("framework"), # Needs to be changed
      slack_channel: slack_channel
  )
end

lane :smf_pod_send_slack_notification do |options|
  smf_super_pod_send_slack_notification(options)
end