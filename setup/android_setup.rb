

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

  # Version Code Management (CBENEFIOS-1881)
  # CI: Jenkins calculates version code once and provides via ENV variable
  # Local: Use Config.json (backward compatible)
  version_code = nil
  if smf_is_ci?
    # Jenkins provides BUILD_VERSION_CODE for all CI builds (single + group)
    if ENV['BUILD_VERSION_CODE']
      version_code = ENV['BUILD_VERSION_CODE'].to_i
      UI.message("🔢 Using version code from Jenkins: #{version_code}")

      if ENV['IS_GROUP_BUILD'] == 'true'
        UI.message("🔗 Group Build - all variants share this version code")
      else
        UI.message("🏗️  Single Build")
      end
    else
      # Fallback if ENV variable not set (shouldn't happen in CI)
      UI.important("⚠️  BUILD_VERSION_CODE not set, falling back to tag-based calculation")
      version_code = smf_get_next_version_code_from_tags('android')
    end
  else
    UI.message("🖥️  Local Build detected - using Config.json for version code")
    version_code = @smf_fastlane_config[:app_version_code]
  end

  smf_build_android_app(
      build_variant: variant,
      keystore_folder: keystore_folder,
      version_code: version_code
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
# NOTE (CBENEFIOS-1881): This lane is deprecated for CI builds
# CI builds now use Git tags for version code management (no Config.json commits)
# This lane is kept for backward compatibility and local builds only

private_lane :smf_super_pipeline_increment_build_number do |options|

  if smf_is_ci?
    UI.important("⚠️  CI Build detected - skipping Config.json increment")
    UI.important("💡 Version code is now managed via Git tags (CBENEFIOS-1881)")
    UI.important("💡 Jenkins jobs should stop calling this lane for CI builds")
    # No-op for CI builds - version code comes from Git tags
    next
  end

  # Local builds: Keep original behavior
  UI.message("🖥️  Local Build - incrementing Config.json")
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

  # Version Code Management (CBENEFIOS-1881)
  # CI: Jenkins provides BUILD_VERSION_CODE for all builds
  # Local: Use Config.json (backward compatible)

  build_number = nil

  if smf_is_ci?
    # Jenkins provides BUILD_VERSION_CODE for all CI builds
    if ENV['BUILD_VERSION_CODE']
      build_number = ENV['BUILD_VERSION_CODE'].to_i
      UI.message("🔢 Using version code from Jenkins for git tag: #{build_number}")
    else
      # Fallback: Try to extract from APK or use Git tags
      UI.important("⚠️  BUILD_VERSION_CODE not set, trying APK extraction")

      apk_file_regex = smf_get_apk_file_regex(build_variant)
      aab_file_regex = smf_get_aab_file_regex(build_variant)

      apk_path = smf_get_file_path(apk_file_regex)
      aab_path = smf_get_file_path(aab_file_regex)

      if apk_path && File.exist?(apk_path)
        build_number = smf_get_current_version_code_from_apk(apk_path)
      elsif aab_path && File.exist?(aab_path)
        UI.message("📦 AAB found, using version code from Git tags")
        build_number = smf_get_next_version_code_from_tags('android')
      end

      if build_number.nil?
        UI.important("⚠️  Could not extract version code from APK/AAB")
        UI.important("💡 Falling back to Git tags")
        build_number = smf_get_next_version_code_from_tags('android')
      end
    end
  else
    UI.message("🖥️  Local Build - using Config.json for version code")
    build_number = smf_get_build_number_of_app
  end

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
  
  # Check if use_aab flag is set for this build variant
  use_aab = smf_config_get(build_variant, :use_aab) || false

  if service_credentials_file.nil?
    UI.message("Skipping upload to Firebase because Firebase credentials are missing.")
    return
  end

  if firebase_app_id.nil?
    UI.message("Skipping upload to Firebase because Firebase app id is missing.")
    return
  end

  if use_aab
    # AAB-only mode: only upload AAB files
    aab_file_regex = smf_get_aab_file_regex(build_variant)
    aab_path = smf_get_file_path(aab_file_regex)
    
    UI.message("AAB-only mode (use_aab=true)")
    UI.message("Path for AAB binary: #{aab_path}")
    
    if aab_path != ''
      smf_android_upload_to_firebase(
        app_id: firebase_app_id,
        destinations: destinations,
        android_artifact_path: aab_path,
        android_artifact_type: "AAB",
        build_variant: build_variant
      )
    else
      UI.user_error!("use_aab=true but no AAB file found for variant: #{build_variant}")
    end
  else
    # Legacy mode: upload both AAB and APK if they exist
    apk_file_regex = smf_get_apk_file_regex(build_variant)
    aab_file_regex = smf_get_aab_file_regex(build_variant)
    
    UI.message("Legacy mode (use_aab=false or not set)")
    UI.message("Regex for binary: #{apk_file_regex}")

    aab_path = smf_get_file_path(aab_file_regex)
    UI.message("Path for AAB binary: #{aab_path}")
    smf_android_upload_to_firebase(
      app_id: firebase_app_id,
      destinations: destinations,
      android_artifact_path: aab_path,
      android_artifact_type: "AAB",
      build_variant: build_variant
    ) if aab_path != ''

    apk_path = smf_get_file_path(apk_file_regex)
    UI.message("Path for APK binary: #{apk_path}")
    smf_android_upload_to_firebase(
      app_id: firebase_app_id,
      destinations: destinations,
      android_artifact_path: apk_path,
      android_artifact_type: "APK",
      build_variant: build_variant
    ) if apk_path != ''
  end
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
  # CI: Extract build number from git tag (not Config.json)
  # Local: Use Config.json (backward compatible)
  if smf_is_ci?
    UI.message("🏗️  CI Build - extracting build number from latest git tag")
    # Get the latest tag for this build variant
    latest_tag = sh("git describe --tags --match '*#{build_variant}*' --abbrev=0 HEAD", log: false).strip
    build_number = latest_tag.split('/').last.to_i
    UI.message("📊 Extracted build number from tag: #{build_number}")
  else
    UI.message("🖥️  Local Build - using Config.json for build number")
    build_number = smf_get_build_number_of_app
  end

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
  google_play_service_account = smf_config_get(nil, :google_play_service_account_json)
  
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
  UI.message("🔍 About to call smf_get_package_name_from_variant with: #{build_variant}")
  package_name = smf_get_package_name_from_variant(build_variant)
  UI.message("🔍 Received package_name: #{package_name}")
  
  # Validate package_name
  if package_name.nil? || package_name.empty?
    UI.user_error!("Package name is nil or empty for build variant: #{build_variant}")
  end
  
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
    # Get marketing version for release notes
    marketing_version = smf_get_version_name
    UI.message("📋 Using marketing version as release name: #{marketing_version}")
    release_notes_xml = get_release_notes_for_version(marketing_version)
    
    # Check for metadata directory with changelogs
    # Note: fastlane runs from the 'fastlane/' directory, so path is relative to that
    # Convert to absolute path to avoid issues with supply changing directories
    metadata_path_relative = "./metadata/android"
    metadata_path_source = File.expand_path(metadata_path_relative)
    has_metadata = File.directory?(metadata_path_source)

    # Get configured locales for this variant (optional, defaults to all available)
    configured_locales = smf_config_get(build_variant, :google_play_locales)

    # Prepare the metadata path (may be filtered or original)
    metadata_path = metadata_path_source
    temp_metadata_dir = nil

    if has_metadata
      if configured_locales && configured_locales.is_a?(Array) && !configured_locales.empty?
        # Create a temporary directory with only the configured locales
        temp_metadata_dir = File.join(Dir.tmpdir, "fastlane_metadata_#{build_variant}_#{Time.now.to_i}")
        FileUtils.mkdir_p(temp_metadata_dir)

        configured_locales.each do |locale|
          source_locale_dir = File.join(metadata_path_source, locale)
          if File.directory?(source_locale_dir)
            FileUtils.cp_r(source_locale_dir, temp_metadata_dir)
          else
            UI.important("⚠️ Configured locale '#{locale}' not found in metadata directory")
          end
        end

        metadata_path = temp_metadata_dir
        UI.message("📝 Found metadata directory - will upload changelogs")
        UI.message("🌍 Filtered locales: #{configured_locales.join(', ')}")
        UI.message("📂 Temp metadata path: #{metadata_path}")
      else
        UI.message("📝 Found metadata directory - will upload changelogs (all locales)")
        UI.message("📂 Absolute path: #{metadata_path}")
      end
    else
      UI.message("📝 No metadata directory found at #{metadata_path_relative} - skipping changelogs")
    end

    # Determine release status (default: draft, configurable via google_play_release_status)
    release_status = smf_config_get(build_variant, :google_play_release_status) || 'draft'

    # Check if we should also create a draft in alpha track
    also_draft_to_alpha = smf_config_get(build_variant, :google_play_also_draft_to_alpha) || false

    # Log changelog status
    if has_metadata
      UI.message("📝 Changelogs will be uploaded from #{metadata_path}")
    end

    # Prepare upload parameters
    upload_params = {
      package_name: package_name,
      track: google_play_track,
      json_key: ENV['GOOGLE_PLAY_SERVICE_ACCOUNT_JSON'],
      release_status: release_status,
      version_name: marketing_version,
      skip_upload_metadata: true,
      skip_upload_changelogs: !has_metadata,
      skip_upload_images: true,
      skip_upload_screenshots: true
    }

    # Add metadata path if directory exists
    if has_metadata
      upload_params[:metadata_path] = metadata_path
    end

    # Add the binary file
    if file_type == "AAB"
      upload_params[:aab] = upload_file
    else
      upload_params[:apk] = upload_file
    end

    UI.message("🚀 Uploading to #{google_play_track} track (status: #{release_status})...")

    # Upload to Google Play Store
    upload_to_play_store(upload_params)

    UI.success("✅ Uploaded to #{google_play_track} track (#{release_status})")

    # If also_draft_to_alpha is enabled, promote as a separate step
    if also_draft_to_alpha && google_play_track != 'alpha'
      UI.message("📋 Promoting to alpha track as draft...")

      promote_params = {
        package_name: package_name,
        track: google_play_track,
        track_promote_to: 'alpha',
        track_promote_release_status: 'draft',
        json_key: ENV['GOOGLE_PLAY_SERVICE_ACCOUNT_JSON'],
        skip_upload_apk: true,
        skip_upload_aab: true,
        skip_upload_metadata: true,
        skip_upload_changelogs: true,
        skip_upload_images: true,
        skip_upload_screenshots: true
      }

      upload_to_play_store(promote_params)
      UI.success("✅ Promoted to alpha track (draft)")
    end

    UI.success("✅ All Google Play uploads completed for #{build_variant}")

  rescue => ex
    UI.error("❌ Google Play Store upload failed: #{ex.message}")
    raise ex
  ensure
    # Clean up temporary metadata directory if created
    if temp_metadata_dir && File.directory?(temp_metadata_dir)
      FileUtils.rm_rf(temp_metadata_dir)
      UI.message("🧹 Cleaned up temporary metadata directory")
    end
  end
end

# Helper function to find the best upload file (respects use_aab flag)
def find_best_upload_file(build_variant)
  # Check if use_aab flag is set for this build variant
  use_aab = smf_config_get(build_variant, :use_aab) || false
  
  if use_aab
    # AAB-only mode: only look for AAB files
    aab_path = smf_get_file_path(smf_get_aab_file_regex(build_variant))
    
    if aab_path && File.exist?(aab_path)
      return {
        path: aab_path,
        type: "AAB",
        detection_reason: "AAB found (use_aab=true)"
      }
    else
      # No AAB found but use_aab is true - this is an error
      UI.user_error!("use_aab=true but no AAB file found for variant: #{build_variant}")
    end
  else
    # Legacy mode: APK preferred, AAB fallback
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
  end
  
  # No suitable file found
  return nil
end

# Helper function to determine if rollout should be included
def should_include_rollout(track, release_status)
  # Draft releases don't support rollout percentage
  return false if release_status == 'draft'
  
  # Internal testing doesn't typically use rollout
  return false if track == 'internal'
  
  # Alpha, beta, and production tracks support rollout when not draft
  ['alpha', 'beta', 'production'].include?(track)
end

# Helper function to get rollout percentage based on track
def get_rollout_percentage(track)
  case track
  when 'internal'
    1.0  # 100% for internal testing
  when 'alpha'
    1.0  # 100% for alpha testing
  when 'beta'
    1.0  # 100% rollout for beta
  when 'production'
    0.1  # 10% rollout for production
  when 'internal'
    1.0  # 100% for internal testing
  else
    1.0  # Default to 100%
  end
end

# Helper function to get marketing version name from build.gradle
def smf_get_version_name
  # Get current working directory for debugging
  current_dir = Dir.pwd
  UI.message("🔍 Current directory: #{current_dir}")
  
  # List all files in current directory for debugging
  UI.message("📁 Directory contents: #{Dir.entries(current_dir).join(', ')}")
  
  # Try to find build.gradle in comprehensive locations
  build_gradle_paths = [
    'app/build.gradle',
    'app/build.gradle.kts',
    './app/build.gradle',
    './app/build.gradle.kts',
    './androidApp/build.gradle.kts',
    File.join(current_dir, 'app', 'build.gradle'),
    File.join(current_dir, 'app', 'build.gradle.kts'),
    # Additional paths for different Jenkins workspace structures
    'build.gradle',
    './build.gradle',
    File.join(current_dir, 'build.gradle'),
    # Go up one directory from fastlane folder
    '../app/build.gradle',
    '../app/build.gradle.kts',
    '../androidApp/build.gradle.kts',
    File.join(current_dir, '..', 'app', 'build.gradle'),
    File.join(current_dir, '..', 'app', 'build.gradle.kts'),
    '../build.gradle',
    '../build.gradle.kts',
    File.join(current_dir, '..', 'build.gradle')
  ]
  
  # Also search recursively for build.gradle files
  Dir.glob('**/build.gradle*').each do |file|
    build_gradle_paths << file unless build_gradle_paths.include?(file)
  end
  
  build_gradle_paths.each do |path|
    begin
      if File.exist?(path)
        UI.message("📄 Reading version from: #{path}")
        build_gradle = File.read(path)
        
        # Try multiple patterns for Kotlin DSL and Groovy
        patterns = [
          /versionName\s+"([^"]+)"/,           # versionName "2.3.2"
          /versionName\s+'([^']+)'/,           # versionName '2.3.2'
          /versionName\s*=\s*"([^"]+)"/,       # versionName = "2.3.2"
          /versionName\s*=\s*'([^']+)'/        # versionName = '2.3.2'
        ]
        
        patterns.each do |pattern|
          match = build_gradle.match(pattern)
          if match
            version_name = match.captures.first
            UI.message("✅ Found version: #{version_name} in #{path}")
            return version_name
          end
        end
        
        UI.message("⚠️ No versionName pattern matched in #{path}")
      else
        UI.message("📄 File not found: #{path}")
      end
    rescue => e
      UI.message("❌ Error reading #{path}: #{e.message}")
    end
  end
  
  # Fallback to gradle.properties in multiple locations
  gradle_properties_paths = [
    'gradle.properties',
    './gradle.properties',
    File.join(current_dir, 'gradle.properties'),
    'app/gradle.properties',
    './app/gradle.properties',
    File.join(current_dir, 'app', 'gradle.properties'),
    # Go up one directory from fastlane folder
    '../gradle.properties',
    '../app/gradle.properties',
    File.join(current_dir, '..', 'gradle.properties'),
    File.join(current_dir, '..', 'app', 'gradle.properties')
  ]
  
  # Also search recursively for gradle.properties files
  Dir.glob('**/gradle.properties').each do |file|
    gradle_properties_paths << file unless gradle_properties_paths.include?(file)
  end
  
  gradle_properties_paths.each do |path|
    begin
      if File.exist?(path) && File.read(path).include?('versionName')
        gradle_properties = File.read(path)
        version_name = gradle_properties.match(/versionName\s*=\s*(.+)/)&.captures&.first&.strip&.gsub(/["']/, '')
        UI.message("✅ Found version in gradle.properties: #{version_name}")
        return version_name
      end
    rescue => e
      UI.message("⚠️ Could not read #{path}: #{e.message}")
    end
  end
  
  # Final fallback: Try to get version from Config.json
  begin
    UI.message("🔍 Checking Config.json for app_version_name...")
    UI.message("🔍 @smf_fastlane_config present: #{!@smf_fastlane_config.nil?}")
    UI.message("🔍 @smf_fastlane_config type: #{@smf_fastlane_config.class}")
    
    if @smf_fastlane_config && @smf_fastlane_config.is_a?(Hash)
      UI.message("🔍 Config.json keys: #{@smf_fastlane_config.keys}")
      app_version_name = @smf_fastlane_config[:app_version_name]
      UI.message("🔍 app_version_name value: #{app_version_name}")
      
      if app_version_name && !app_version_name.empty?
        UI.message("✅ Found version in Config.json: #{app_version_name}")
        return app_version_name
      else
        UI.message("⚠️ app_version_name is empty or nil in Config.json")
      end
    else
      UI.message("⚠️ @smf_fastlane_config is not a valid hash")
    end
  rescue => e
    UI.message("⚠️ Could not read version from Config.json: #{e.message}")
  end
  
  # No version found - raise error instead of fallback
  UI.user_error!("❌ Could not find versionName in any build.gradle, gradle.properties, or Config.json files. Please ensure your Android project has a valid versionName defined.")
end

# Helper function to get release notes for marketing version
def get_release_notes_for_version(marketing_version)
  # Try multiple possible paths for release notes (avoiding metadata/ to prevent Fastlane conflicts)
  changelog_paths = [
    "release_notes/#{marketing_version}.xml",
    "fastlane/release_notes/#{marketing_version}.xml", 
    "./release_notes/#{marketing_version}.xml",
    "../fastlane/release_notes/#{marketing_version}.xml"
  ]
  
  changelog_paths.each do |changelog_file|
    if File.exist?(changelog_file)
      UI.message("Found multilingual release notes: #{changelog_file}")
      return File.read(changelog_file).strip
    end
  end
  
  UI.message("No release notes file found in any of these paths: #{changelog_paths.join(', ')}")
  return nil
end

# Helper function to copy XML to Fastlane's default changelog location
def copy_xml_to_default_changelog(xml_content)
  require 'fileutils'
  
  begin
    # Create metadata directory structure
    changelog_dir = 'metadata/android/changelogs'
    FileUtils.mkdir_p(changelog_dir)
    
    # Write XML content to default.txt for Fastlane to find
    default_changelog = File.join(changelog_dir, 'default.txt')
    File.write(default_changelog, xml_content)
    
    UI.message("📝 Created default changelog: #{default_changelog}")
    UI.message("📋 XML content ready for Google Play")
    
    return true
    
  rescue => e
    UI.error("❌ Failed to create default changelog: #{e.message}")
    return false
  end
end

# Helper function to get package name from build variant
def smf_get_package_name_from_variant(build_variant)
  UI.message("🔍 Getting package name for build variant: #{build_variant}")
  
  base_package = nil
  
  # Try to extract package name from AndroidManifest.xml (most reliable for built variants)
  base_package = extract_package_from_manifest(build_variant) if base_package.nil?
  
  # Fallback: try to read from build.gradle (primary source)
  base_package = extract_package_from_build_gradle(build_variant) if base_package.nil?
  
  # Fallback: try to read from gradle.properties
  base_package = extract_package_from_gradle_properties if base_package.nil?
  
  # If still no package found, raise error
  if base_package.nil? || base_package.empty?
    UI.user_error!("❌ Could not extract package name from AndroidManifest.xml, build.gradle, or gradle.properties for variant: #{build_variant}")
  end
  
  # Apply variant-specific suffix if needed
  case build_variant
  when /alpha/i
    package_name = "#{base_package}.alpha"
  when /beta/i  
    package_name = "#{base_package}.beta"
  else
    package_name = base_package
  end
  
  UI.message("✅ Package name for #{build_variant}: #{package_name}")
  return package_name
end

# Helper function to extract package name from AndroidManifest.xml
def extract_package_from_manifest(build_variant)
  # Try different possible manifest locations
  manifest_paths = [
    "app/build/intermediates/merged_manifests/#{build_variant}/AndroidManifest.xml",
    "app/build/intermediates/manifests/full/#{build_variant}/AndroidManifest.xml", 
    "app/src/main/AndroidManifest.xml"
  ]
  
  manifest_paths.each do |manifest_path|
    if File.exist?(manifest_path)
      UI.message("📄 Reading package from manifest: #{manifest_path}")
      manifest_content = File.read(manifest_path)
      package_match = manifest_content.match(/package="([^"]+)"/)
      if package_match
        package_name = package_match.captures.first
        UI.message("✅ Found package in manifest: #{package_name}")
        return package_name
      end
    end
  end
  
  UI.message("⚠️ No AndroidManifest.xml found or package attribute missing")
  return nil
end

# Helper function to extract package name from build.gradle with product flavor support
def extract_package_from_build_gradle(build_variant = nil)
  build_gradle_paths = [
    'app/build.gradle',
    'app/build.gradle.kts',
    'composeApp/build.gradle.kts',
    'androidApp/build.gradle.kts',
    './app/build.gradle',
    './app/build.gradle.kts',
    './composeApp/build.gradle.kts',
    './androidApp/build.gradle.kts',
    # From fastlane directory perspective (go up one level)
    '../app/build.gradle',
    '../app/build.gradle.kts',
    '../composeApp/build.gradle.kts',
    '../androidApp/build.gradle.kts'
  ]

  build_gradle_paths.each do |path|
    if File.exist?(path)
      UI.message("📄 Reading package from build.gradle: #{path}")
      build_gradle = File.read(path)

      # If we have a build variant, try to extract flavor-specific applicationId first
      if build_variant
        flavor_package = extract_flavor_application_id(build_gradle, build_variant)
        if flavor_package
          UI.message("✅ Found flavor-specific package in build.gradle: #{flavor_package}")
          return flavor_package
        end
      end

      # Fallback: try to find default applicationId
      patterns = [
        /applicationId\s+"([^"]+)"/,           # applicationId "package.name"
        /applicationId\s+'([^']+)'/,           # applicationId 'package.name'
        /applicationId\s*=\s*"([^"]+)"/,       # applicationId = "package.name"
        /applicationId\s*=\s*'([^']+)'/,       # applicationId = 'package.name'
        /applicationId\s*=\s*([^"\s\}]+)/      # applicationId = variable
      ]

      patterns.each do |pattern|
        match = build_gradle.match(pattern)
        if match
          package_name = match.captures.first.strip
          UI.message("✅ Found default package in build.gradle: #{package_name}")
          return package_name
        end
      end
    end
  end

  UI.message("⚠️ No build.gradle found or applicationId missing")
  return nil
end

# Helper function to extract flavor-specific applicationId from build.gradle content
def extract_flavor_application_id(build_gradle_content, build_variant)
  # Extract flavor name from build variant (e.g., "ch_live" -> "switzerland", "de_alpha" -> "germany")
  flavor_mapping = {
    'ch' => 'switzerland',
    'de' => 'germany',
    'at' => 'austria',
    'es' => 'spain',
    'it' => 'italy',
    'be' => 'benelux',
    'pt' => 'portugal',
    'pl' => 'poland',
    'tr' => 'turkey'
  }

  # Try to determine flavor from build variant
  detected_flavor = nil
  flavor_mapping.each do |prefix, flavor_name|
    if build_variant.downcase.start_with?(prefix + '_') || build_variant.downcase.include?(flavor_name)
      detected_flavor = flavor_name
      break
    end
  end

  return nil unless detected_flavor

  UI.message("🔍 Looking for flavor '#{detected_flavor}' in build.gradle")

  # Look for the specific flavor block and extract its applicationId
  # Pattern: create("flavorname") { ... applicationId = "package.name" ... }
  flavor_block_regex = /create\("#{detected_flavor}"\)\s*\{([^}]*(?:\{[^}]*\}[^}]*)*)\}/m

  match = build_gradle_content.match(flavor_block_regex)
  if match
    flavor_content = match.captures.first
    UI.message("📦 Found flavor block for '#{detected_flavor}'")

    # Extract applicationId from the flavor block
    app_id_patterns = [
      /applicationId\s*=\s*"([^"]+)"/,
      /applicationId\s*=\s*'([^']+)'/,
      /applicationId\s+"([^"]+)"/,
      /applicationId\s+'([^']+)'/
    ]

    app_id_patterns.each do |pattern|
      app_id_match = flavor_content.match(pattern)
      if app_id_match
        return app_id_match.captures.first.strip
      end
    end
  end

  UI.message("⚠️ No applicationId found for flavor '#{detected_flavor}'")
  return nil
end

# Helper function to extract package name from gradle.properties
def extract_package_from_gradle_properties
  gradle_properties_path = 'gradle.properties'
  
  if File.exist?(gradle_properties_path)
    UI.message("📄 Reading package from gradle.properties")
    gradle_properties = File.read(gradle_properties_path)
    
    if gradle_properties.include?('applicationId')
      package_match = gradle_properties.match(/applicationId\s*=\s*(.+)/)
      if package_match
        package_name = package_match.captures.first.strip.gsub(/["']/, '')
        UI.message("✅ Found package in gradle.properties: #{package_name}")
        return package_name
      end
    end
  end
  
  UI.message("⚠️ No gradle.properties found or applicationId missing")
  return nil
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
