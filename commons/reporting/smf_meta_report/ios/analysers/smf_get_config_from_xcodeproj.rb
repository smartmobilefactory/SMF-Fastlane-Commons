#!/usr/bin/ruby
require 'json'

def smf_xcodeproj_settings
  # Xcodebuild command info:
  # '-configuration' the 'Release' configuration is taken by default
  # '-scheme' by default only the first scheme is used. We shall specify the scheme
  # in case we want to analyze a non-default one.
  # TODO: Use -scheme
  puts smf_xcodeproj_file_path

  json_string = `xcodebuild -project #{smf_xcodeproj_file_path} -showBuildSettings -json`
  xcode_settings = JSON.parse(json_string)
  return xcode_settings
end

# Return the configuration value associated to the given key from the xcode project
# Parameters:
#   - config_key: The xcode config key to retrieve the value from (ex: 'SWIFT_VERSION')
#   - xcode_settings: Optional json of the already retrieve xcodeproj's build settings.
#                     Use this to optimize the process and avoid multiple settings analyses.
#                     If empty or not specified the function `smf_xcodeproj_settings`
#                     will be called.
def smf_xcodeproj_settings_get(config_key, xcode_settings=[])
  if xcode_settings.empty?
    xcode_settings = smf_xcodeproj_settings
  end

  buildSettings = xcode_settings[0].dig('buildSettings')
  config_value = buildSettings.dig(config_key)

  json_string = `xcodebuild -project #{smf_xcodeproj_file_path} -list -json`
  xcodeproj_targets = JSON.parse(json_string).dig('project').dig('targets')

  for target in xcodeproj_targets
    target_json_string = `xcodebuild -project #{smf_xcodeproj_file_path} -target #{target} -showBuildSettings -json`
    target_settings = JSON.parse(target_json_string)[0].dig('buildSettings')
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