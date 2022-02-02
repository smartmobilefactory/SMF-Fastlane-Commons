#!/usr/bin/ruby
require 'json'

# Returns nil if it fails
def _smf_xcode_settings(opt_string)

  retry_counter = 0
  max_retries = 3

  # Retry loop because sometimes the xcodebuild .. call fails and produces no valid json string
  # which causes the JSON.parse call to fail
  while retry_counter < max_retries do
    begin
      json_string = `xcodebuild -project "#{smf_xcodeproj_file_path}" #{opt_string}`
      parsed_json = JSON.parse(json_string)
      return parsed_json
    rescue
      retry_counter += 1
    end
  end
end

# Returns a json representing the xcode's build settings of either the default target
# or if specified of a dedicated scheme.
#
# xcodebuild command info:
# '-configuration' the 'Release' configuration is taken by default
# '-scheme' by default xcodebuild uses the first scheme. We shall specify the scheme
# in case we want to analyze a non-default one.
def smf_xcodeproj_settings(options = {})

  build_variant = options[:build_variant]
  if !build_variant.nil? && build_variant != ''
    scheme_name = smf_config_get(build_variant, :scheme)
    if !scheme_name.nil? && scheme_name != ''
      scheme = "-scheme \"#{scheme_name}\""
    end
  end

  settings = _smf_xcode_settings("#{scheme} -showBuildSettings -json")

  return {} unless settings

  settings
end

def smf_xcodeproj_targets

  settings = _smf_xcode_settings("-list -json")

  return [] unless settings

  settings.dig('project').dig('targets')
end

def smf_xcodeproj_target_settings(target)

  settings = _smf_xcode_settings("-target \"#{target}\" -showBuildSettings -json")

  return {} unless settings

  settings[0].dig('buildSettings')
end

# Return the configuration value associated to the given key from the xcode project
# Parameters:
#   - config_key: The xcode config key to retrieve the value from (ex: 'SWIFT_VERSION')
#   - xcode_settings: Optional json of the already retrieve xcodeproj's build settings.
#                     Use this to optimize the process and avoid multiple settings analyses.
#                     If empty or not specified the function `smf_xcodeproj_settings`
#                     will be called.
#   - options: the current job options containing the build_variant
#   - ignore_unit_tests_targets: if set to true 'AppTests' targets will be skipped
def smf_xcodeproj_settings_get(config_key, xcode_settings = {}, options = {}, ignore_unit_tests_targets = false)
  if xcode_settings.empty?
    xcode_settings = smf_xcodeproj_settings(options)
  end

  return nil if xcode_settings.empty?

  config_value = xcode_settings[0].dig('buildSettings', config_key)
  targets = smf_xcodeproj_targets

  return nil if targets.empty?

  for target in targets
    unless ignore_unit_tests_targets && target == 'AppTests'

      target_settings = smf_xcodeproj_target_settings(target)
      target_config_value = target_settings.dig(config_key)

      if !target_config_value.nil? && target_config_value != ''
        puts "Target '#{target}': { #{config_key}: #{target_config_value} }"
      end

      if config_value.nil?
        config_value = target_config_value
      elsif !target_config_value.nil? && target_config_value != '' && config_value != target_config_value
        message = "Multiple #{config_key} were found in the \"#{@smf_fastlane_config[:project][:project_name]}\": '#{config_value}' and '#{target_config_value}'"
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
  end
  return config_value
end
