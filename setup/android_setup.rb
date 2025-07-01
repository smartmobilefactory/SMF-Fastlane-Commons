
########## PULLREQUEST CHECK LANES ##########

# Setup Dependencies

private_lane :smf_super_setup_dependencies do |options|
end

lane :smf_setup_dependencies_pr_check do |options|
  smf_super_setup_dependencies(options)
end

lane :smf_setup_dependencies_build do |options|
  smf_super_setup_dependencies(options)
end


# Build (Build to Release)

private_lane :smf_super_build do |options|

  if options.nil?
    UI.important("No options were provided. 'options' is nil.")
  else
    UI.message("Options provided: #{options.inspect}")
  end

  build_variant = !options[:build_variant].nil? ? options[:build_variant] : smf_get_first_variant_from_config

  UI.message("Build variant: #{build_variant}")

  variant = smf_get_build_variant_from_config(build_variant)

  UI.message("Variant: #{variant}")

  keystore_folder = smf_get_keystore_folder(build_variant)

  UI.message("Keystore: #{keystore_folder}")

  smf_build_android_app(
      build_variant: variant,
      keystore_folder: keystore_folder
  )
end

lane :smf_build do |options|
  smf_super_build(options)
end


# Run Unit Tests

private_lane :smf_super_run_unit_tests do |options|
  smf_run_junit_task
end

lane :smf_run_unit_tests do |options|
  smf_super_run_unit_tests(options)
end


# Linter

private_lane :smf_super_linter do |options|

  build_variant = !options[:build_variant].nil? ? options[:build_variant] : smf_get_first_variant_from_config
  options[:build_variant] = smf_get_build_variant_from_config(build_variant)

  smf_run_klint(options)
  smf_run_detekt(options)
  smf_run_gradle_lint_task(options)
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
  build_variant = options[:build_variant]
  smf_linter(options)
  smf_report_metrics(build_variant: build_variant)
end

lane :smf_report do |options|
  # smf_super_report(options)
end

############ AUTOMATIC REPORTING LANES ############
###########  For Unit-Tests Reporting  ############

private_lane :smf_super_android_automatic_reporting do |options|

  project_name = @smf_fastlane_config.dig(:project, :project_name)
  branch_name = !options[:branch_name].nil? ? options[:branch_name] : smf_workspace_dir_git_branch

  smf_android_monitor_unit_tests(
    project_name: project_name,
    branch: branch_name,
    platform: smf_meta_report_platform_friendly_name
  )
end

lane :smf_android_automatic_reporting do |options|
  smf_super_android_automatic_reporting(options)
end

########## ADDITIONAL LANES USED FOR BUILDING ##########

# Generate Changelog

private_lane :smf_super_generate_changelog do |options|

  build_variant = options[:build_variant]

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

  build_variant = options[:build_variant]
  build_number = smf_get_build_number_of_app
  smf_create_git_tag(build_variant: build_variant, build_number: build_number)
end

lane :smf_pipeline_create_git_tag do |options|
  smf_super_pipeline_create_git_tag(options)
end


# Upload to AppCenter (Deprecated - AppCenter service discontinued)
# This functionality has been removed as AppCenter is no longer available


# Push Git Tag / Release

private_lane :smf_super_push_git_tag_release do |options|

  local_branch = options[:local_branch]
  build_variant = options[:build_variant]

  changelog = smf_read_changelog

  smf_git_pull(local_branch)
  smf_push_to_git_remote(local_branch: local_branch)

  # Create the GitHub release
  build_number = smf_get_build_number_of_app
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
  project_name = smf_get_default_name_and_version(build_variant)
  slack_channel = @smf_fastlane_config[:project][:slack_channel]

  smf_send_default_build_success_notification(
      name: project_name,
      slack_channel: slack_channel
  )
end

lane :smf_send_slack_notification do |options|
  smf_super_send_slack_notification(options)
end
