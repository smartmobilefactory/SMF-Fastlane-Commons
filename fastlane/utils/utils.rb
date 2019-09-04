
# Uses Config file to access project name. Should be changed in the future.
def get_build_number_of_app
  UI.message('Get the build number of project.')
  case @platform
  when :ios
    project_name = @smf_fastlane_config[:project][:project_name]
    build_number = get_build_number(xcodeproj: "#{project_name}.xcodeproj")
  when :android
    build_number = @smf_fastlane_config[:app_version_code].to_s
  when :flutter
    UI.message('get build number of project for flutter is not implemented yet')
  else
    UI.message("There is no platform \"#{@platform}\", exiting...")
    raise 'Unknown platform'
  end

  if build_number.include? '.'
    parts = build_number.split('.')
    build_number = parts[0]
  end

  build_number
end

def get_xcconfig_name(build_variant)
  build_variant_config = @smf_fastlane_config[:build_variants][build_variant]
  use_xcconfig = build_variant_config[:xcconfig_name].nil? ? false : true
  use_xcconfig ? build_variant_config[:xcconfig_name][:archive] : "Release"
end

def get_icloud_environmet(build_variant)
  build_variant_config = @smf_fastlane_config[:build_variants][build_variant]
  build_variant_config[:icloud_environment].nil? ? "Development" : build_variant_config[:icloud_environment]
end