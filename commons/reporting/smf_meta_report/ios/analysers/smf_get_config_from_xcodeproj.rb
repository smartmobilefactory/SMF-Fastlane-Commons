#!/usr/bin/ruby
require 'json'

def smf_xcodeproj_settings(options={})
  # Xcodebuild command info:
  # '-configuration' the 'Release' configuration is taken by default
  # '-scheme' by default xcodebuild uses the first scheme. We shall specify the scheme
  # in case we want to analyze a non-default one.

  json_string = ""
  build_variant = options[:build_variant]
  if !build_variant.nil? && build_variant != ''
    scheme = smf_config_get(build_variant, :scheme)
    json_string = `xcodebuild -project #{smf_xcodeproj_file_path} -scheme #{scheme} -showBuildSettings -json`
  else
    json_string = `xcodebuild -project #{smf_xcodeproj_file_path} -showBuildSettings -json`
  end

  xcode_settings = JSON.parse(json_string)
  return xcode_settings
end

def smf_xcodeproj_targets()
  json_string = `xcodebuild -project #{smf_xcodeproj_file_path} -list -json`
  xcodeproj_targets = JSON.parse(json_string).dig('project').dig('targets')

  return xcodeproj_targets
end

def smf_xcodeproj_target_settings(target)
  json_string = `xcodebuild -project #{smf_xcodeproj_file_path} -target #{target} -showBuildSettings -json`
  json = JSON.parse(json_string)[0].dig('buildSettings')

  return json
end

# Return the configuration value associated to the given key from the xcode project
# Parameters:
#   - config_key: The xcode config key to retrieve the value from (ex: 'SWIFT_VERSION')
#   - xcode_settings: Optional json of the already retrieve xcodeproj's build settings.
#                     Use this to optimize the process and avoid multiple settings analyses.
#                     If empty or not specified the function `smf_xcodeproj_settings`
#                     will be called.
#   - options: the current job options containing the build_variant
def smf_xcodeproj_settings_get(config_key, xcode_settings=[], options)
  if xcode_settings.empty?
    xcode_settings = smf_xcodeproj_settings(options)
  end

  buildSettings = xcode_settings[0].dig('buildSettings')
  config_value = buildSettings.dig(config_key)

  for target in smf_xcodeproj_targets
    target_settings = smf_xcodeproj_target_settings(target)
    target_config_value = target_settings.dig(config_key)
    puts "Target '#{target}': { #{config_key}: #{target_config_value} }"

    if config_value.nil?
      config_value = target_config_value
    elsif config_value != target_config_value
      raise "[ERROR]: Multiple #{config_key} were found in the \".xcodeproj\": '#{config_value}' and '#{target_config_value}'"
    end
  end

  return config_value
end