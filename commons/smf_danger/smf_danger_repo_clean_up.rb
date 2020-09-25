def _smf_check_repo_files_folders
  active_files_to_remove = []
  _smf_deprecated_files_for_platform.each do |deprecated_file|
    # Check if the files exist within the repo
    if File.exist?("#{smf_workspace_dir}/#{deprecated_file}")
      # if so retain the file and warn developers in PR checks.
      active_files_to_remove.push(deprecated_file)
    end
  end

  ENV['DANGER_REPO_CLEAN_UP_FILES'] = JSON.dump(active_files_to_remove)
end

def _smf_deprecated_files_for_platform
  deprecated_files = $CONFIG_DEPRECATED_FILES_FOLDERS_COMMONS
  case @platform
  when :ios, :ios_framework, :macos, :apple
    deprecated_files += $CONFIG_DEPRECATED_FILES_FOLDERS_IOS
  when :android
    deprecated_files += $CONFIG_DEPRECATED_FILES_FOLDERS_ANDROID
  when :flutter
    deprecated_files += $CONFIG_DEPRECATED_FILES_FOLDERS_FLUTTER
  else
    UI.message("There is no platform \"#{@platform}\", exiting...")
    raise "Unknown platform: #{@platform.to_s}"
  end

  deprecated_files = deprecated_files.map { |key| key.to_s }
  deprecated_files
end

def _smf_check_config_project_missing_required_keys
  # Convert all keys to string for easier matching
  project_config_keys = _get_config(:project).keys.map { |key| key.to_s }
  # Check for missing required keys in the 'config.project' hash
  missing_required_keys = []
  _smf_required_config_keys_for_platform.each do |key|
    # If the required key is NOT present in the config.project hash
    # Then display a warning about it using Danger to ask the dev the add it to the Config.json.
    unless project_config_keys.include?(key.to_s)
      missing_required_keys.push(key.to_s)
    end
  end

  ENV['DANGER_REPO_MISSING_REQUIRED_PROJECT_CONFIG_KEYS'] = JSON.dump(missing_required_keys)
end

def _smf_check_config_project_allowed_only_keys
  # Convert all keys to string for easier matching
  project_config_keys = _get_config(:project).keys.map { |key| key.to_s }
  # Check for non-allowed (or deprecated) keys in the 'config.project' hash
  deprecated_keys = []
  allowed_keys = _smf_optional_config_keys_for_platform + _smf_required_config_keys_for_platform
  project_config_keys.each do |key|
    # If the key is NOT one of the allowed (and required) keys
    # Then display a warning about it using Danger to ask the dev to remove it from the Config.json.
    unless allowed_keys.include?(key)
      deprecated_keys.push(key)
    end
  end

  ENV['DANGER_REPO_CLEAN_UP_PROJECT_CONFIG_KEYS_ONLY'] = JSON.dump(deprecated_keys)
end

def _smf_required_config_keys_for_platform
  required_keys = $CONFIG_REQUIRED_PROJECT_KEYS_COMMONS
  case @platform
  when :ios, :ios_framework, :macos, :apple
    required_keys += $CONFIG_REQUIRED_PROJECT_KEYS_IOS
  when :android
    required_keys += $CONFIG_REQUIRED_PROJECT_KEYS_ANDROID
  when :flutter
    required_keys += $CONFIG_REQUIRED_PROJECT_KEYS_FLUTTER
  else
    UI.message("There is no platform \"#{@platform}\", exiting...")
    raise "Unknown platform: #{@platform.to_s}"
  end

  required_keys = required_keys.map { |key| key.to_s }
  required_keys
end

def _smf_optional_config_keys_for_platform
  optional_keys = $CONFIG_OPTIONAL_PROJECT_KEYS_COMMONS
  case @platform
  when :ios, :ios_framework, :macos, :apple
    optional_keys += $CONFIG_OPTIONAL_PROJECT_KEYS_IOS
  when :android
    optional_keys += $CONFIG_OPTIONAL_PROJECT_KEYS_ANDROID
  when :flutter
    optional_keys += $CONFIG_OPTIONAL_PROJECT_KEYS_FLUTTER
  else
    UI.message("There is no platform \"#{@platform}\", exiting...")
    raise "Unknown platform: #{@platform.to_s}"
  end

  optional_keys = optional_keys.map { |key| key.to_s }
  optional_keys
end


def _smf_check_config_build_variant_keys
  deprecated_keys_in_variant = []
  # For each build_variant present in the Config.json
  _get_config(:build_variants).each do |build_variant, build_variant_info|
    # Convert all build_variant keys to string for easier matching
    build_variant_info_keys = build_variant_info.keys.map { |key| key.to_s }
    build_variant_info_keys.each do |key|
      # Checks for existing keys that have been marked as deprecated
      if _smf_deprecated_build_variant_keys_for_platform.include?(key)
        # Use Danger to ask the dev to remove the key from the Config.json
        deprecated_keys_in_variant.push("#{build_variant}.#{key}")
      end
    end
  end

  ENV['DANGER_REPO_CLEAN_UP_BUILD_VARIANTS'] = JSON.dump(deprecated_keys_in_variant)
end

def _smf_deprecated_build_variant_keys_for_platform
  deprecated_keys = []
  case @platform
  when :ios, :ios_framework, :macos, :apple
    deprecated_keys = $CONFIG_DEPRECATED_BUILD_VARIANT_KEYS_IOS
  when :android
    deprecated_keys = $CONFIG_DEPRECATED_BUILD_VARIANT_KEYS_ANDROID
  when :flutter
    deprecated_keys = $CONFIG_DEPRECATED_BUILD_VARIANT_KEYS_FLUTTER
  else
    UI.message("There is no platform \"#{@platform}\", exiting...")
    raise 'Unknown platform: "#{@platform.to_s}"'
  end

  deprecated_keys = deprecated_keys.map { |key| key.to_s }
  deprecated_keys
end

def _get_config(key)
  config = @smf_fastlane_config[key]
  if config.nil? || config.count == 0
    raise "[ERROR]: Missing or empty '#{key.to_s}' in Config.json"
    return []
  end

  config
end
