# Uses Config file to access project name. Should be changed in the future.
def get_default_name_of_app(build_variant)
  case @platform
  when :ios
    project_name = @smf_fastlane_config[:project][:project_name]
    build_number = get_build_number(xcodeproj: "#{project_name}.xcodeproj")
    version = smf_get_version_number
    "#{project_name} #{build_variant.upcase} #{version} (#{build_number})"
  when :android
    project_name = !@smf_fastlane_config[:project][:name].nil? ? @smf_fastlane_config[:project][:name] : ENV["PROJECT_NAME"]
    "#{project_name} #{build_variant} (Build #{ENV["next_version_code"]})"
  when :flutter
    UI.message('Notification for flutter is not implemented yet')
  else
    UI.message("There is no platform \"#{@platform}\", exiting...")
    raise 'Unknown platform'
  end
end

# Uses Config file to access project name. Should be changed in the future.
def get_default_name_of_pod(build_variant)
  podspec_path = @smf_fastlane_config[:build_variants][build_variant.downcase.to_sym][:podspec_path]
  version = read_podspec(path: podspec_path)["version"]
  pod_name = read_podspec(path: podspec_path)["name"]
  project_name = !@smf_fastlane_config[:project][:project_name].nil? ? @smf_fastlane_config[:project][:project_name] : pod_name
  "#{project_name} #{version}"
end

# Uses Config file to access project name. Should be changed in the future.
def get_build_number_of_project
  UI.message('Get the build number of project from the config file.')
  case @platform
  when :ios
    project_name = @smf_fastlane_config[:project][:project_name]
    get_build_number(xcodeproj: "#{project_name}.xcodeproj")
  when :android
    @smf_fastlane_config["app_version_code"].to_s
  when :flutter
    UI.message('get build number of project for flutter is not implemented yet')
  else
    UI.message("There is no platform \"#{@platform}\", exiting...")
    raise 'Unknown platform'
  end
end

def get_tag_of_app(build_variant, build_number)
  "build/#{build_variant.capitalize}/#{build_number}"
end

def get_tag_of_pod(build_number)
  "releases/#{build_number}"
end