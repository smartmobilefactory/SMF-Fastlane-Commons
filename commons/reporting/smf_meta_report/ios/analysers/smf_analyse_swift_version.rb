#!/usr/bin/ruby

# returns the analysed property
def smf_analyse_swift_version(xcode_settings={}, options={})
  UI.message("Analyser: #{__method__.to_s} ...")

  # Grab custom swift version, if any
  swift_version = smf_xcodeproj_settings_get('SWIFT_VERSION', xcode_settings, options)

  if swift_version.nil?
    # Otherwise use the default swift version related to the xcode version used by the project.
    swift_version = _smf_get_default_swift_version_for_xcode
  end

  if swift_version.nil?
    UI.important("Project might not contained any Swift code or is not programmed in Swift!")
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

  return swift_version
end
