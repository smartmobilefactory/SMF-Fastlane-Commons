

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

#Upload to Firebase
private_lane :smf_super_upload_to_firebase do |options|

  build_variant = smf_build_variant(options)
  
  service_credentials_file = ENV['FIREBASE_CREDENTIALS']

  firebase_app_id = smf_get_firebase_id(build_variant)
  destinations = smf_config_get(build_variant, :firebase_destinations) || "RWC"
  apk_file_regex = smf_get_apk_file_regex(build_variant)
  aab_file_regex = smf_get_aab_file_regex(build_variant)

  UI.message("Regex for binary: #{apk_file_regex}")

  if service_credentials_file.nil?
    UI.message("Skipping upload to Firebase because Firebase credentials are missing.")
    return
  end

  if firebase_app_id.nil?
    UI.message("Skipping upload to Firebase because Firebase app id is missing.")
    return
  end

  aab_path = smf_get_file_path(aab_file_regex)
  UI.message("Path for AAB binary: #{aab_path}")
  smf_android_upload_to_firebase(
    app_id: firebase_app_id,
    destinations: destinations,
    android_artifact_path: aab_path,
    android_artifact_type: "AAB"
  ) if aab_path != ''

  apk_path = smf_get_file_path(apk_file_regex)
  UI.message("Path for APK binary: #{apk_path}")
  smf_android_upload_to_firebase(
    app_id: firebase_app_id,
    destinations: destinations,
    android_artifact_path: apk_path,
    android_artifact_type: "APK"
  ) if apk_path != ''
end

lane :smf_upload_to_firebase do |options|
  smf_super_upload_to_firebase(options)
end

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

desc "Upload Android app to Google Play Store"
private_lane :smf_super_upload_to_play_store do |options|
  build_variant = options[:build_variant]
  
  # Get configuration from Config.json
  google_play_track = smf_config_get(build_variant, :google_play_track)
  google_play_upload = smf_config_get(build_variant, :google_play_upload)
  google_play_service_account = smf_config_get(:google_play_service_account_json)
  
  # Skip if Google Play upload is disabled for this variant
  unless google_play_upload
    UI.message("Google Play Store upload disabled for variant: #{build_variant}")
    return
  end
  
  # Validate required configuration
  if google_play_track.nil? || google_play_track.empty?
    UI.user_error!("google_play_track not configured for variant: #{build_variant}")
  end
  
  if google_play_service_account.nil? || google_play_service_account.empty?
    UI.user_error!("google_play_service_account_json not configured")
  end
  
  # Get package name from build variant configuration
  package_name = smf_get_package_name_from_variant(build_variant)
  
  # Find best upload file: APK preferred, AAB fallback
  upload_file_info = find_best_upload_file(build_variant)
  
  if upload_file_info.nil?
    UI.user_error!("Neither APK nor AAB file found for variant: #{build_variant}")
  end
  
  upload_file = upload_file_info[:path]
  file_type = upload_file_info[:type]
  
  UI.message("📦 Uploading #{file_type} to Google Play Store...")
  UI.message("🎯 Track: #{google_play_track}")
  UI.message("📱 Package: #{package_name}")
  UI.message("📄 File: #{upload_file}")
  UI.message("ℹ️  Detection: #{upload_file_info[:detection_reason]}")
  
  begin
    # Prepare upload parameters
    upload_params = {
      package_name: package_name,
      track: google_play_track,
      json_key: ENV['GOOGLE_PLAY_SERVICE_ACCOUNT_JSON'],
      release_status: 'completed',
      rollout: get_rollout_percentage(google_play_track),
      skip_upload_metadata: true,
      skip_upload_changelogs: false,
      skip_upload_images: true,
      skip_upload_screenshots: true
    }
    
    # Add the appropriate file parameter
    if file_type == "AAB"
      upload_params[:aab] = upload_file
    else
      upload_params[:apk] = upload_file
    end
    
    # Upload to Google Play Store
    upload_to_play_store(upload_params)
    
    UI.success("✅ Successfully uploaded #{build_variant} to Google Play Store (#{google_play_track} track)")
    
  rescue => ex
    UI.error("❌ Google Play Store upload failed: #{ex.message}")
    raise ex
  end
end

# Helper function to find the best upload file (APK preferred, AAB fallback)
def find_best_upload_file(build_variant)
  # Try to find APK first (preferred for current SMF projects)
  apk_path = smf_get_file_path(smf_get_apk_file_regex(build_variant))
  
  if apk_path && File.exist?(apk_path)
    return {
      path: apk_path,
      type: "APK",
      detection_reason: "APK found and preferred for legacy compatibility"
    }
  end
  
  # Fallback to AAB (for projects that are fully migrated)
  aab_path = smf_get_file_path(smf_get_aab_file_regex(build_variant))
  
  if aab_path && File.exist?(aab_path)
    return {
      path: aab_path,
      type: "AAB",
      detection_reason: "AAB found as fallback (no APK available)"
    }
  end
  
  # No suitable file found
  return nil
end

# Helper function to get rollout percentage based on track
def get_rollout_percentage(track)
  case track
  when 'internal'
    1.0  # 100% for internal testing
  when 'alpha'
    1.0  # 100% for alpha testing
  when 'beta'
    0.5  # 50% rollout for beta
  when 'production'
    0.1  # 10% rollout for production
  else
    1.0  # Default to 100%
  end
end

# Helper function to get package name from build variant
def smf_get_package_name_from_variant(build_variant)
  gradle_properties = File.read('gradle.properties') rescue ''
  
  if gradle_properties.include?('applicationId')
    base_package = gradle_properties.match(/applicationId\s*=\s*(.+)/)&.captures&.first&.strip&.gsub(/["']/, '')
  else
    # Fallback: read from build.gradle
    build_gradle = File.read('app/build.gradle') rescue ''
    base_package = build_gradle.match(/applicationId\s+["'](.+)["']/)&.captures&.first
  end
  
  # Apply variant-specific suffix if needed
  case build_variant
  when /alpha/i
    "#{base_package}.alpha"
  when /beta/i
    "#{base_package}.beta"
  else
    base_package
  end
end

lane :smf_upload_to_play_store do |options|
  smf_super_upload_to_play_store(options)
end

desc "Upload Android app to both Firebase and Google Play Store"
lane :smf_upload_to_all_platforms do |options|
  build_variant = options[:build_variant]
  
  # Upload to Firebase App Distribution
  if smf_config_get(build_variant, :firebase_app_id)
    UI.message("🔥 Uploading to Firebase App Distribution...")
    smf_upload_to_firebase(options)
  end
  
  # Upload to Google Play Store
  if smf_config_get(build_variant, :google_play_upload)
    UI.message("🎯 Uploading to Google Play Store...")
    smf_upload_to_play_store(options)
  end
end
