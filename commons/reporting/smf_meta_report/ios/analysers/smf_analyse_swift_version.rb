#!/usr/bin/ruby

require 'json'

# returns the analysed property
def smf_analyse_swift_version(xcode_settings)
  UI.message("Analyser: #{__method__.to_s} ...")

  # Grab custom swift version, if any
  swift_version = _smf_grab_custom_swift_version_for_pbxproj(xcode_settings)
  if swift_version.nil?
    # Otherwise use the default swift version related to the xcode version used by the project.
    swift_version = _smf_get_default_swift_version_for_xcode
  end

  if swift_version.nil?
    UI.important("Project might not contained any Swift code or is not programmed in Swift!")
  end

  swift_version
end

# Within the project.pbxproj, the SWIFT_VERSION is set when a developer has manually configured it.
# If he/she hasn't the variable isn't set in the xml and the default value is used (auto-configured by Xcode).
def _smf_grab_custom_swift_version_for_pbxproj(xcode_settings)
  buildSettings = xcode_settings[0].dig('buildSettings')
  swift_version = buildSettings.dig('SWIFT_VERSION')

  json_string = `xcodebuild -project #{smf_xcodeproj_file_path} -list -json`
  xcodeproj_targets = JSON.parse(json_string).dig('project').dig('targets')

  for target in xcodeproj_targets
    target_json_string = `xcodebuild -project #{smf_xcodeproj_file_path} -target #{target} -showBuildSettings -json`
    target_settings = JSON.parse(target_json_string)[0].dig('buildSettings')
    target_swift_version = target_settings.dig('SWIFT_VERSION')

    if swift_version.nil?
      swift_version = target_swift_version
    elsif swift_version != target_swift_version
      raise "[ERROR]: Multiple SWIFT_VERSION were found in the \"project.pbxproj\": '#{swift_version}' and '#{target_swift_version}'"
    end
  end

  return swift_version
end

def _smf_get_default_swift_version_for_xcode
  xcode_version = @smf_fastlane_config[:project][:xcode_version]
  if xcode_version.nil?
    raise "[ERROR]: Missing 'xcode_version' from Config.json"
  end

  verbose_version = `/Applications/Xcode-#{xcode_version}.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift -version`

  swift_version = nil
  if swift_version_match = verbose_version.match("([0-9.]+)")
    swift_version = swift_version_match.captures[0]
  end

  swift_version
end
