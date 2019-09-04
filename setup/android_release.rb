# setup Dependencies

private_lane :super_setup_dependencies do |options|
end

lane :setup_dependencies do |options|
  super_setup_dependencies(options)
end


# Run Unit Tests

private_lane :super_run_unit_tests do |options|
end

lane :run_unit_tests do |options|
  super_run_unit_tests(options)
end


# Increment Build Number

private_lane :super_increment_build_number do |options|

  build_variant = options[:build_variant]

  smf_increment_build_number(build_variant: build_variant)
end

# increment_build_number already exists
lane :pipeline_increment_build_number do |options|
  super_increment_build_number(options)
end


# Build

private_lane :super_build do |options|

  build_variant = options[:build_variant]

  variant = get_build_variant_from_config(build_variant)

  smf_build_android_app(build_variant: variant)
end

lane :build do |options|
  super_build(options)
end

# Generate Changelog

private_lane :super_generate_changelog do |options|

  build_variant = options[:build_variant]

  smf_git_changelog(build_variant: build_variant)
end

lane :generate_changelog do |options|
  super_generate_changelog(options)
end

# Upload to AppCenter

private_lane :super_upload_to_appcenter do |options|

  build_variant = options[:build_variant]
  apk_file_regex = get_apk_file_regex(build_variant)
  app_id = get_app_center_id(build_variant)

  smf_android_upload_to_appcenter(
      build_variant: build_variant,
      apk_path: get_apk_path(apk_file_regex),
      app_secret: app_id
  )
end

# upload_to_appcenter already exists
lane :pipeline_upload_to_appcenter do |options|
  super_upload_to_appcenter(options)
end

# Push Git Tag / Release

private_lane :super_push_git_tag_release do |options|

  branch = options[:branch]

  smf_push_to_git_remote(local_branch: branch)
end

lane :push_git_tag_release do |options|
  super_push_git_tag_release(options)
end

# Send Slack Notification

private_lane :super_send_slack_notification do |options|

  build_variant = options[:build_variant]
  project_name = get_default_name_of_app(build_variant)

  smf_send_default_build_success_notification(
      build_variant: build_variant,
      name: project_name
  )
end

lane :send_slack_notification do |options|
  super_send_slack_notification(options)
end