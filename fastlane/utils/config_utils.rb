
def smf_update_config(config, message = nil)
  jsonString = JSON.pretty_generate(config)
  File.write("#{smf_workspace_dir}/Config.json", jsonString)
  git_add(path: "#{smf_workspace_dir}/Config.json")
  git_commit(path: "#{smf_workspace_dir}/Config.json", message: message || 'Update Config.json')
end

def smf_get_first_variant_from_config
  variant = @smf_fastlane_config[:build_variants].keys.map(&:to_s).first
  raise('There is no build variant in Config.') if variant.nil?

  variant
end

# function which returns true if we are currently
# building a mac app in a catalyst project
def smf_is_catalyst_mac_build(build_variant)
  build_variant.to_s.start_with?($CATALYST_MAC_BUILD_VARIANT_PREFIX) && @platform == :apple
end

def smf_is_mac_build(build_variant)
  is_catalyst_mac = smf_is_catalyst_mac_build(build_variant)
  is_mac = smf_config_get(build_variant.to_sym, :is_mac_app)

  is_catalyst_mac || is_mac
end

# access helper to get the correct config.json entry for a given
# platform and build variant
def smf_config_get(build_variant, *keys)
  build_variant = build_variant.to_sym
  return @smf_fastlane_config.dig(*keys) if build_variant.nil?

  build_variant_config = @smf_fastlane_config[:build_variants].dig(build_variant)
  return nil if build_variant_config.nil?

  case @platform
  when :apple
    if smf_is_catalyst_mac_build(build_variant)
      value = build_variant_config.dig(:alt_platforms, :macOS, *keys)
      return build_variant_config.dig(:alt_platforms, :macOS, *keys) unless value.nil?
    end

    return build_variant_config.dig(*keys)
  when :ios, :macos, :ios_framework, :android, :flutter
    build_variant_config.dig(*keys)
  else
    return nil
  end
end

#################### SPECIAL GETTER ####################

def smf_get_icloud_environment(build_variant)

  icloud_environment = 'Development'

  case @platform
  when :ios, :ios_framework, :macos, :apple
    icloud_environment = @smf_fastlane_config.dig(
      :build_variants,
      build_variant,
      :icloud_environment
    )

  when :flutter
    icloud_environment = @smf_fastlane_config.dig(
      :build_variants,
      build_variant,
      :ios,
      :icloud_environment
    )
  end

  icloud_environment
end

def smf_get_xcconfig_name(build_variant)

  xcconfig_name = 'Release'

  case @platform
  when :ios, :ios_framework, :macos, :apple
    xcconfig_name = @smf_fastlane_config.dig(
       :build_variants,
       build_variant,
       :xcconfig_name,
       :archive
    )
  when :flutter
    xcconfig_name = @smf_fastlane_config.dig(
      :build_variants,
      build_variant,
      :ios,
      :xcconfig_name,
      :archive
    )
  end

  xcconfig_name
end

def smf_get_meta_db_project_name
  name = @smf_fastlane_config.dig(:project, :meta_db_name)
  return @smf_fastlane_config.dig(:project, :project_name) if name.nil?

  name
end
