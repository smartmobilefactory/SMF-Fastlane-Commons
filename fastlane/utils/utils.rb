# Uses Config file to access project name. Should be changed in the future.
def get_default_name_of_app(build_variant)
  build_number = smf_get_build_number_of_app
  case @platform
  when :ios
    project_name = @smf_fastlane_config[:project][:project_name]
    "#{project_name} #{build_variant.upcase} (#{build_number})"
  when :android
    project_name = !@smf_fastlane_config[:project][:name].nil? ? @smf_fastlane_config[:project][:name] : ENV['PROJECT_NAME']
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
  version = read_podspec(path: podspec_path)['version']
  pod_name = read_podspec(path: podspec_path)['name']
  project_name = !@smf_fastlane_config[:project][:project_name].nil? ? @smf_fastlane_config[:project][:project_name] : pod_name
  "#{project_name} #{version}"
end

# Uses Config file to access project name. Should be changed in the future.
def smf_get_build_number_of_app
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

def smf_get_xcconfig_name(build_variant)
  build_variant_config = @smf_fastlane_config[:build_variants][build_variant]
  use_xcconfig = build_variant_config[:xcconfig_name].nil? ? false : true
  use_xcconfig ? build_variant_config[:xcconfig_name][:archive] : "Release"
end

def smf_get_icloud_environment(build_variant)
  build_variant_config = @smf_fastlane_config[:build_variants][build_variant]
  build_variant_config[:icloud_environment].nil? ? "Development" : build_variant_config[:icloud_environment]
end

def smf_get_app_secret(build_variant)
  UI.message("build_variant: #{build_variant}")
  build_variant = build_variant.to_s.downcase
  case @platform
  when :ios
    @smf_fastlane_config[:build_variants][build_variant.to_sym][:hockeyapp_id]
  when :android
    @smf_fastlane_config[:hockey][build_variant.to_sym]
  when :flutter
    UI.message('App Secret for flutter is not implemented yet')
  else
    UI.message("There is no platform \"#{@platform}\", exiting...")
    raise 'Unknown platform'
  end
end

def smf_path_to_ipa_or_app(build_variant)

  escaped_filename = @smf_fastlane_config[:build_variants][build_variant.to_sym][:scheme].gsub(' ', "\ ")

  app_path = Pathname.getwd.dirname.to_s + "/build/#{escaped_filename}.ipa.zip"
  app_path = Pathname.getwd.dirname.to_s + "/build/#{escaped_filename}.ipa" unless File.exist?(app_path)

  UI.message("Constructed path \"#{app_path}\" from filename \"#{escaped_filename}\"")

  unless File.exist?(app_path)
    app_path = lane_context[SharedValues::IPA_OUTPUT_PATH]

    UI.message("Using \"#{app_path}\" as app_path as no file exists at the constructed path.")
  end

  app_path
end

def ci_ios_error_log
  $SMF_CI_IOS_ERROR_LOG.to_s
end