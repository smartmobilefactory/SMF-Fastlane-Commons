# Setup Dependencies - pod install & `sh generate.sh` (optional: Phrase App)

private_lane :smf_super_shared_setup_dependencies do |options|

  build_variant = !options[:build_variant].nil? ? options[:build_variant] : smf_get_first_variant_from_config

  smf_pod_install

  build_variant_config = @smf_fastlane_config[:build_variants][build_variant.to_sym]

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
  smf_super_setup_dependencies(options)
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


# Run Unit Tests

private_lane :smf_super_ios_run_unit_tests do |options|

  build_variant = !options[:build_variant].nil? ? options[:build_variant] : smf_get_first_variant_from_config

  build_variant_config = @smf_fastlane_config[:build_variants][build_variant.to_sym]

  smf_ios_unit_tests(
      project_name: "Runner",
      unit_test_scheme: build_variant_config[:ios][:unit_test_scheme],
      scheme: build_variant_config[:ios][:scheme],
      unit_test_xcconfig_name: !build_variant_config[:ios][:xcconfig_name].nil? ? build_variant_config[:ios][:xcconfig_name][:unittests] : nil,
      device: build_variant_config["tests.device_to_test_against".to_sym],
      required_xcode_version: @smf_fastlane_config[:project][:xcode_version]
  )

end

lane :smf_ios_run_unit_tests do |options|
  smf_super_ios_run_unit_tests(options)
end

private_lane :smf_super_android_run_unit_tests do |options|
  smf_run_junit_task(options)
end

lane :smf_run_android_unit_tests do |options|
  smf_super_android_run_unit_tests(options)
end


# Linter

private_lane :smf_super_ios_linter do
  smf_run_swift_lint
end

lane :smf_ios_linter do |options|
  smf_super_ios_linter
end

private_lane :smf_super_android_linter do |options|

  build_variant = !options[:build_variant].nil? ? options[:build_variant] : smf_get_first_variant_from_config
  options[:build_variant] = smf_get_build_variant_from_config(build_variant)

  smf_run_klint(options)
  smf_run_detekt(options)
  smf_run_gradle_lint_task(options)
end

lane :smf_android_linter do |options|
  smf_super_android_linter(options)
end


# Danger

private_lane :smf_super_shared_pipeline_danger do |options|
  smf_danger(options)
end

lane :smf_shared_pipeline_danger do |options|
  smf_super_shared_pipeline_danger(options)
end

