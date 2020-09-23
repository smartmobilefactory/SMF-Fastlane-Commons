#!/usr/bin/ruby

# returns the analysed property
def smf_analyse_swift_version
  UI.message("Analyser: #{__method__.to_s} ...")

  # Grab custom swift version, if any
  swift_version = _smf_grab_custom_swift_version_for_pbxproj
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
def _smf_grab_custom_swift_version_for_pbxproj
  swift_version = nil
  grab = "#{`fgrep -R "SWIFT_VERSION = " #{smf_pbxproj_file_path}`}"
  grab.split("\n").each do |config|
    # Extract Swift version from each line of the output of fgrep.
    if swift_version_match = config.match("([0-9.]+);$")
      matched_version = swift_version_match.captures[0]
      # Check if the swift version is consistent or not
      if swift_version.nil?
        swift_version = matched_version
      elsif swift_version != matched_version
        raise "[ERROR]: Multiple SWIFT_VERSION were found in the \"project.pbxproj\": '#{swift_version}' and '#{matched_version}'"
      end
    end
  end

  swift_version
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
