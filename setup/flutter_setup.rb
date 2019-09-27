# Setup Dependencies - pod install & `sh generate.sh` (optional: Phrase App)

private_lane :smf_super_shared_setup_dependencies do |options|

  build_variant = !options[:build_variant].nil? ? options[:build_variant] : smf_get_first_variant_from_config
  build_variant_config = @smf_fastlane_config[:build_variants][build_variant.to_sym]

  sh("cd #{smf_workspace_dir}; ./flutterw doctor")

  generate_sh_file = "#{smf_workspace_dir}/generate.sh"
  if File.exist?(generate_sh_file)
    sh("cd #{smf_workspace_dir}; sh generate.sh")
  end

  # Called only when upload_itc is set to true. This way the build will fail in the beginning if there are any problems with itc. Saves time.
  smf_verify_itc_upload_errors(
      build_variant: build_variant,
      upload_itc: build_variant_config[:upload_itc],
      project_name: @smf_fastlane_config[:project][:project_name],
      itc_skip_version_check: build_variant_config[:itc_skip_version_check],
      username: build_variant_config[:itc_apple_id],
      itc_team_id: build_variant_config[:itc_team_id],
      bundle_identifier: build_variant_config[:bundle_identifier]
  )
end

lane :smf_shared_setup_dependencies_pr_check do |options|
  smf_super_shared_setup_dependencies(options)
end

lane :smf_setup_dependencies_build do |options|
  smf_super_shared_setup_dependencies(options)
end


# Update Jenkinsfile

private_lane :smf_shared_super_generate_files do |options|

  build_variant = !options[:build_variant].nil? ? options[:build_variant] : smf_get_first_variant_from_config

  smf_update_generated_files(
      branch: options[:branch],
      build_variant: build_variant
  )
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
  sh("cd #{smf_workspace_dir}; ./flutterw build ios --release --no-codesign --flavor #{build_variant}")
end

lane :smf_ios_build do |options|
  smf_super_ios_build(options)
end

private_lane :smf_super_android_build do |options|
  build_variant = !options[:build_variant].nil? ? options[:build_variant] : smf_get_first_variant_from_config
  sh("cd #{smf_workspace_dir}; ./flutterw build apk --release --flavor #{build_variant}")
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


# Upload to AppCenter

private_lane :smf_super_pipeline_android_upload_to_appcenter do |options|

  build_variant = options[:build_variant]
  apk_file_regex = smf_get_apk_file_regex(build_variant)
  appcenter_app_id = smf_get_appcenter_id(build_variant, 'android')
  hockey_app_id = smf_get_hockey_id(build_variant, 'android')

  # Upload to AppCenter
  smf_android_upload_to_appcenter(
      build_variant: build_variant,
      apk_path: smf_get_apk_path(apk_file_regex),
      app_id: appcenter_app_id
  ) if !appcenter_app_id.nil?

  # Upload to Hockey
  smf_android_upload_to_hockey(
      build_variant: build_variant,
      apk_path: smf_get_apk_path(apk_file_regex),
      app_id: hockey_app_id
  ) if !hockey_app_id.nil?

end

lane :smf_pipeline_android_upload_to_appcenter do |options|
  smf_super_pipeline_android_upload_to_appcenter(options)
end

private_lane :smf_super_pipeline_ios_upload_to_appcenter do |options|
  build_variant = options[:build_variant]
  build_variant_config = @smf_fastlane_config[:build_variants][options[:build_variant].to_sym]
  appcenter_app_id = smf_get_appcenter_id(build_variant, "ios")
  hockey_app_id = smf_get_hockey_id(build_variant, "ios")

  # Upload the IPA to AppCenter
  smf_ios_upload_to_appcenter(
      build_number: smf_get_build_number_of_app,
      app_id: appcenter_app_id,
      escaped_filename: build_variant_config[:scheme].gsub(' ', "\ "),
      path_to_ipa_or_app: smf_path_to_ipa_or_app(build_variant),
      is_mac_app: build_variant_config[:use_sparkle],
      podspec_path: build_variant_config[:podspec_path]
  ) if !appcenter_app_id.nil?

  # Upload the IPA to Hockey
  smf_ios_upload_to_hockey(
      build_number: smf_get_build_number_of_app,
      app_id: hockey_app_id,
      escaped_filename: build_variant_config[:scheme].gsub(' ', "\ "),
      path_to_ipa_or_app: smf_path_to_ipa_or_app(build_variant),
      is_mac_app: build_variant_config[:use_sparkle],
      podspec_path: build_variant_config[:podspec_path]
  ) if !hockey_app_id.nil?

end

lane :smf_pipeline_ios_upload_to_appcenter do |options|
  smf_super_pipeline_ios_upload_to_appcenter(options)
end


# Run Unit Tests

private_lane :smf_super_run_unit_tests do |options|
  sh("cd #{smf_workspace_dir}; ./flutterw test")
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
  sh("cd #{smf_workspace_dir}; ./flutterw analyze")
end

lane :smf_linter do |options|
  smf_super_linter(options)
end


# Danger

private_lane :smf_super_shared_pipeline_danger do |options|
  smf_danger(options)
end

lane :smf_shared_pipeline_danger do |options|
  smf_super_shared_pipeline_danger(options)
end

