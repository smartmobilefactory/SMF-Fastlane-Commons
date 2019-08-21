# Uses Config file to access project name. Should be changed in the future.
def get_default_name_of_app(build_variant)
  build_number = get_build_number_of_app
  case @platform
  when :ios
    project_name = @smf_fastlane_config[:project][:project_name]
    "#{project_name} #{build_variant.upcase} (#{build_number})"
  when :android
    project_name = !@smf_fastlane_config[:project][:name].nil? ? @smf_fastlane_config[:project][:name] : ENV["PROJECT_NAME"]
    "#{project_name} #{build_variant} (Build #{build_number})"
  when :flutter
    UI.message('Notification for flutter is not implemented yet')
  else
    UI.message("There is no platform \"#{@platform}\", exiting...")
    raise 'Unknown platform'
  end
end

# Uses Config file to access project name. Should be changed in the future.
def get_default_name_of_pod
  podspec_path = @smf_fastlane_config[:build_variants][@smf_build_variant_sym][:podspec_path]
  version = read_podspec(path: podspec_path)["version"]
  pod_name = read_podspec(path: podspec_path)["name"]
  project_name = !@smf_fastlane_config[:project][:project_name].nil? ? @smf_fastlane_config[:project][:project_name] : pod_name
  "#{project_name} #{version}"
end

# Uses Config file to access project name. Should be changed in the future.
def get_build_number_of_app
  UI.message('Get the build number of project.')
  case @platform
  when :ios
    project_name = @smf_fastlane_config[:project][:project_name]
    build_number = get_build_number(xcodeproj: "#{project_name}.xcodeproj")
  when :android
    build_number = @smf_fastlane_config["app_version_code"].to_s
  when :flutter
    UI.message('get build number of project for flutter is not implemented yet')
  else
    UI.message("There is no platform \"#{@platform}\", exiting...")
    raise 'Unknown platform'
  end

  if build_number.include? '.'
    parts = build_number.split('.')
    parts[0]
  else
    build_number
  end
end

def get_tag_of_pod(version_number)
  "releases/#{version_number}"
end

def get_project_name
  @smf_fastlane_config[:project][:project_name]
end

def smf_is_keychain_enabled
  return ENV[$SMF_IS_KEYCHAIN_ENABLED].nil? ? true : ENV[$SMF_IS_KEYCHAIN_ENABLED] == "true"
end

def get_extension_suffixes
  @smf_fastlane_config[:extensions_suffixes]
end

def get_required_xcode_version
  @smf_fastlane_config[:project][:xcode_version]
end

##################################
###  Build variant config      ###
##################################
def build_variant_config
  @smf_fastlane_config[:build_variants][@smf_build_variant_sym]
end

def get_build_scheme
  build_variant_config[:scheme]
end

def get_upload_itc
  build_variant_config[:upload_itc].nil? ? false : build_variant_config[:upload_itc]
end

def get_upload_bitcode
  build_variant_config[:upload_bitcode].nil? ? true : build_variant_config[:upload_bitcode]
end

def get_use_xcconfig
  build_variant_config[:xcconfig_name].nil? ? false : true
end

def get_xcconfig_name
  use_xcconfig = build_variant_config[:xcconfig_name].nil? ? false : true
  use_xcconfig ? build_variant_config[:xcconfig_name][:archive] : "Release"
end

def get_export_method
  build_variant_config[:export_method]
end

def get_icloud_environment
  build_variant_config[:icloud_environment].nil? ? "Development" : build_variant_config[:icloud_environment]
end

def get_code_signing_identity
  build_variant_config[:code_signing_identity]
end

def get_use_sparkle
  build_variant_config[:use_sparkle].nil? ? false : build_variant_config[:use_sparkle]
end

def get_use_wildcard_signing
  build_variant_config[:use_wildcard_signing]
end

def get_team_id
  build_variant_config[:team_id]
end

def get_apple_id
  build_variant_config[:apple_id]
end

def get_bundle_identifier
  build_variant_config[:bundle_identifier]
end

def get_is_adhoc_build
  @smf_build_variant.include? "adhoc"
end

def match_config
  build_variant_config[:match]
end

def get_match_config_read_only
  match_config[:read_only]
end

def get_match_config_type
  match_config[:type]
end