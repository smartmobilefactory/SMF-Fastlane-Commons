
# Setup Workspace

private_lane :super_setup_workspace do |options|
  smf_setup_workspace
end

private_lane :setup_workspace do |options|
  super_setup_workspace(options)
end


# Setup Dependencies

private_lane :super_setup_dependencies do |options|
end

private_lane :setup_dependencies do |options|
  super_setup_dependencies(options)
end


# Run Unit Tests

private_lane :super_run_unit_tests do |options|
end

private_lane :run_unit_tests do |options|
  super_run_unit_tests(options)
end


# Increment Build Number

private_lane :super_increment_build_number do |options|

  build_variant = options[:build_variant]

  smf_increment_build_number(build_variant: build_variant)
end

private_lane :increment_build_number do |options|
end


# Build

private_lane :super_build do |options|

  build_variant = options[:build_variant]

  smf_build_app(build_variant: build_variant)
end

private_lane :build do |options|
  super_build(options)
end

# Generate Changelog

private_lane :super_generate_changelog do |options|

  build_variant = options[:build_variant]

  smf_git_changelog(build_variant: build_variant)
end

private_lane :generate_changelog do |options|
  super_generate_changelog(options)
end

# Upload to AppCenter

private_lane :super_upload_to_appcenter do |options|

  build_variant = options[:build_variant]
  apk_file_name = options[:apk_file_name] # From Fastfile, maybe now from Config?
  app_secret = @smf_fastlane_config

  smf_android_upload_to_appcenter(
      build_variant: build_variant,
      apk_file: apk_file_name,
      app_secret: app_secret
  )
end

private_lane :upload_to_appcenter do |options|
  super_upload_to_appcenter(options)
end

# Push Git Tag / Release

private_lane :super_push_git_tag_release do |options|

  branch = options[:branch]

  smf_push_to_git_remote(local_branch: branch)
end

private_lane :push_git_tag_release do |options|
  super_push_git_tag_release(options)
end

# Send Slack Notification

private_lane :super_send_slack_notification do |options|

  build_variant = options[:build_variant]
  project_name = options[:project_name] # From Config

  smf_send_default_build_success_notification(
      build_variant: build_variant,
      name: project_name
  )
end

private_lane :send_slack_notification do |options|
  super_send_slack_notification(options)
end