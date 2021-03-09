#!/usr/bin/ruby
require 'json'

# Returns a json representing the xcode's build settings of either the default target
# or if specified of a dedicated scheme.
#
# xcodebuild command info:
# '-configuration' the 'Release' configuration is taken by default
# '-scheme' by default xcodebuild uses the first scheme. We shall specify the scheme
# in case we want to analyze a non-default one.
def smf_xcodeproj_settings(options={})
  json_string = ""
  scheme = ""

  build_variant = options[:build_variant]
  if !build_variant.nil? && build_variant != ''
    scheme_name = smf_config_get(build_variant, :scheme)
    if !scheme_name.nil? && scheme_name != ''
      scheme = "-scheme #{scheme_name}"
    end
  end

  json_string = `xcodebuild -project "#{smf_xcodeproj_file_path}" #{scheme} -showBuildSettings -json`
  xcode_settings = JSON.parse(json_string)
  return xcode_settings
end

def smf_xcodeproj_targets
  json_string = `xcodebuild -project "#{smf_xcodeproj_file_path}" -list -json`
  xcodeproj_targets = JSON.parse(json_string).dig('project').dig('targets')

  return xcodeproj_targets
end

def smf_xcodeproj_target_settings(target)
  json_string = `xcodebuild -project "#{smf_xcodeproj_file_path}" -target #{target} -showBuildSettings -json`
  json = JSON.parse(json_string)[0].dig('buildSettings')

  return json
end

def smf_xcodeproj_name
  path = smf_xcodeproj_file_path
  xcodeproj_name = path.match(/\/([^\/]+)$/)[1]

  return xcodeproj_name
end

# Return the configuration value associated to the given key from the xcode project
# Parameters:
#   - config_key: The xcode config key to retrieve the value from (ex: 'SWIFT_VERSION')
#   - xcode_settings: Optional json of the already retrieve xcodeproj's build settings.
#                     Use this to optimize the process and avoid multiple settings analyses.
#                     If empty or not specified the function `smf_xcodeproj_settings`
#                     will be called.
#   - options: the current job options containing the build_variant
def smf_xcodeproj_settings_get(config_key, xcode_settings={}, options={})
  if xcode_settings.empty?
    xcode_settings = smf_xcodeproj_settings(options)
  end

  buildSettings = xcode_settings[0].dig('buildSettings')
  config_value = buildSettings.dig(config_key)

  for target in smf_xcodeproj_targets
    target_settings = smf_xcodeproj_target_settings(target)
    target_config_value = target_settings.dig(config_key)
    if !target_config_value.nil? && target_config_value != ''
      puts "Target '#{target}': { #{config_key}: #{target_config_value} }"
    end

    if config_value.nil?
      config_value = target_config_value
    elsif !target_config_value.nil? && target_config_value != '' && config_value != target_config_value
      message = "Multiple #{config_key} were found in the \"#{smf_xcodeproj_name}\": '#{config_value}' and '#{target_config_value}'"
      ENV["DANGER_#{config_key}"] = message
      # Send a Slack notification if the current build is not a PR check but a build release.
      # For PRs, Danger checks the ENV variables and adds warnings directly on GitHub during the PR review.
      if ENV['CHANGE_ID'].nil?
        smf_send_message(
          title: 'Inconsistent configuration in xcodeproj',
          message: message,
          type: 'error'
        )
      end
    end
  end

  return config_value
end
