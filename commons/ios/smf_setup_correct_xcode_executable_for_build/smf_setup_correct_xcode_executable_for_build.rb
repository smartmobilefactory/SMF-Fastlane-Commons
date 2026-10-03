# Returns the Xcode bundle to build with. Without a pinned version the project
# follows /Applications/Xcode.app, i.e. whichever Xcode the node has installed
# under the default name.
def smf_xcode_executable_path(required_xcode_version)
  return $XCODE_DEFAULT_EXECUTABLE_PATH if required_xcode_version.to_s.strip.empty?

  "#{$XCODE_EXECUTABLE_PATH_PREFIX}#{required_xcode_version}#{$XCODE_EXECUTABLE_PATH_POSTFIX}"
end

private_lane :smf_setup_correct_xcode_executable_for_build do |options|
  # Make sure that the correct xcode version is selected when building the app

  required_xcode_version = options[:required_xcode_version]
  xcode_executable_path = smf_xcode_executable_path(required_xcode_version)

  ENV[$DEVELOPMENT_DIRECTORY_KEY] = xcode_executable_path

  xcode_select(xcode_executable_path)

  if required_xcode_version.to_s.strip.empty?
    UI.message("No xcode_version pinned in Config.json, building with #{xcode_executable_path}")
  else
    ensure_xcode_version(version: required_xcode_version)
  end
end
