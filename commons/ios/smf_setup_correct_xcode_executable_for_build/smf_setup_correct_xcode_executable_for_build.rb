private_lane :smf_setup_correct_xcode_executable_for_build do |options|
  # Make sure that the correct xcode version is selected when building the app
  required_xcode_version = options[:required_xcode_version]
  xcode_executable_path = "#{$XCODE_EXECUTABLE_PATH_PREFIX}" + required_xcode_version + "#{$XCODE_EXECUTABLE_PATH_POSTFIX}"

  ENV[$DEVELOPMENT_DIRECTORY_KEY] = xcode_executable_path

  xcode_select(xcode_executable_path)
  ensure_xcode_version(version: required_xcode_version)
end
