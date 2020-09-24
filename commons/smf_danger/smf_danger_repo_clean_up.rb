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

  deprecated_files
end

def _smf_check_config_project_keys
  project_config = @smf_fastlane_config[:project]
  if project_config.nil?
    UI.error("[ERROR]: Missing 'project' info in Config.json")
  end

  required_keys = _smf_required_config_keys_for_platform
  UI.message("List of required keys: #{required_keys}")
  deprecated_keys = []
  project_config.keys.each do |key|
    # Retain the key if it is NOT required (eg. allowed) to warn the dev about it.
    UI.message("Is key '#{key}' NOT in the list?")
    if required_keys.include?(key.to_s)
      UI.message("The key '#{key}' is VALID ")
    else
      UI.message("The key '#{key}' is DEPRECATED and should be removed")
      deprecated_keys.push(key)
    end
  end

  UI.message("Complete list of deprecated_keys: #{deprecated_keys}")
  ENV['DANGER_REPO_CLEAN_UP_PROJECT_CONFIG_KEYS'] = JSON.dump(deprecated_keys)
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

  required_keys
end

def _smf_check_config_build_variant_keys
  build_variants = @smf_fastlane_config[:build_variants]
  if build_variants.nil? || build_variants.count == 0
    UI.error("[ERROR]: Missing or empty 'build_variants' in Config.json")
  end

  deprecated_keys = _smf_deprecated_build_variant_keys_for_platform
  deprecated_keys_in_variant = []
  build_variants.each do |build_variant, build_variant_info|
    build_variant_info.keys.each do |key|
      # For each build_variant
      # Checks for keys that have been marked as deprecated
      if deprecated_keys.include?(key)
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

  deprecated_keys
end