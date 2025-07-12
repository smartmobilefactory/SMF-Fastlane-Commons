# SMF Fastlane Commons - Google Play Store Upload Lane
# Copy this to: /commons/smf_upload_to_play_store/smf_upload_to_play_store.rb

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
  
  # Find best upload file: APK preferred, AAB as fallback
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
    # Generate release notes
    release_notes = generate_release_notes(build_variant)
    
    # Prepare upload parameters
    upload_params = {
      package_name: package_name,
      track: google_play_track,
      json_key: ENV['GOOGLE_PLAY_SERVICE_ACCOUNT_JSON'],
      release_status: 'completed',
      rollout: get_rollout_percentage(google_play_track),
      metadata_path: nil,
      changelogs_path: nil,
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

# Helper function to generate release notes
def generate_release_notes(build_variant)
  changelog_path = smf_read_changelog
  
  if changelog_path && File.exist?(changelog_path)
    return File.read(changelog_path).strip
  else
    version_name = smf_get_version_name
    return "Release #{version_name} - Build #{build_variant}"
  end
end

# Helper function to get package name from build variant
def smf_get_package_name_from_variant(build_variant)
  # This should be implemented based on how package names are determined
  # For now, we'll use a fallback approach
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

# Public lane for external use
lane :smf_upload_to_play_store do |options|
  smf_super_upload_to_play_store(options)
end