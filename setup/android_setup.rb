# Setup Dependencies

private_lane :smf_super_setup_dependencies do |options|
end

lane :smf_setup_dependencies do |options|
  smf_super_setup_dependencies(options)
end


# Run Unit Tests

private_lane :smf_super_run_unit_tests do |options|
  smf_run_junit_task(options)
end

lane :smf_run_unit_tests do |options|
  smf_super_run_unit_tests(options)
end


# Increment Build Number

private_lane :smf_super_pipeline_increment_build_number do |options|

  build_variant = options[:build_variant]

  smf_increment_build_number(build_variant: build_variant)
end

lane :smf_pipeline_increment_build_number do |options|
  smf_super_pipeline_increment_build_number(options)
end


# Build (Build to Release)

private_lane :smf_super_build do |options|

  build_variant = options[:build_variant]

  variant = smf_get_build_variant_from_config(build_variant)

  smf_build_android_app(build_variant: variant)
end

lane :smf_build do |options|
  smf_super_build(options)
end


# Generate Changelog

private_lane :smf_super_generate_changelog do |options|

  build_variant = options[:build_variant]

  smf_git_changelog(build_variant: build_variant)
end

lane :smf_generate_changelog do |options|
  smf_super_generate_changelog(options)
end


# Upload to AppCenter

private_lane :smf_super_upload_to_appcenter do |options|

  build_variant = options[:build_variant]
  apk_file_regex = smf_get_apk_file_regex(build_variant)
  app_id = smf_get_appcenter_id(build_variant)

  smf_android_upload_to_appcenter(
      build_variant: build_variant,
      apk_path: smf_get_apk_path(apk_file_regex),
      app_secret: app_id
  )
end

lane :smf_upload_to_appcenter do |options|
  smf_super_upload_to_appcenter(options)
end


# Push Git Tag / Release

private_lane :smf_super_push_git_tag_release do |options|

  branch = options[:branch]

  smf_git_pull(branch)
  smf_push_to_git_remote(local_branch: branch)
end

lane :smf_push_git_tag_release do |options|
  smf_super_push_git_tag_release(options)
end


# Send Slack Notification

private_lane :smf_super_send_slack_notification do |options|

  build_variant = options[:build_variant]
  project_name = smf_get_default_name_of_app(build_variant)

  smf_send_default_build_success_notification(
      build_variant: build_variant,
      name: project_name
  )
end

lane :smf_send_slack_notification do |options|
  smf_super_send_slack_notification(options)
end


# Linter

private_lane :smf_super_linter do |options|

  build_variant = options[:build_variant]

  options[:build_variant] = smf_get_build_variant_from_config(build_variant)

  smf_run_klint(options)
  smf_run_detekt(options)
  smf_run_gradle_lint_task(options)
end

lane :smf_linter do |options|
  smf_super_linter(options)
end


# Danger

private_lane :smf_super_danger do |options|
  smf_danger
end

lane :smf_pipeline_danger do |options|
  smf_super_danger(options)
end


# Update Android Commons

private_lane :smf_super_update_android_commons do |options|
  smf_update_android_commons(options)
end

lane :smf_pipeline_update_android_commons do |options|
  smf_super_update_android_commons(options)
end