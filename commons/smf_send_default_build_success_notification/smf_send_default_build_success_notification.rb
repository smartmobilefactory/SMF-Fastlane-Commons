private_lane :smf_send_default_build_success_notification do |options|

  build_variant = options[:build_variant]
  slack_channel = @smf_fastlane_config[:project][:slack_channel]

  # Collect the changelog (again) in case the build job failed before the former changelog collecting
  smf_git_changelog(build_variant: build_variant) if ENV[$SMF_CHANGELOG_ENV_KEY].nil?
  UI.message("test 1")
  name = !@smf_fastlane_config[:build_variants][@smf_build_variant_sym][:podspec_path].nil? ? get_default_name_of_pod : get_default_name_of_app(build_variant)
  UI.message("test 2")
  smf_send_message(
      title: "*🎉🛠 Successfully built #{name} 🛠🎉*",
      type: 'success',
      message: ENV[$SMF_CHANGELOG_ENV_KEY],
      slack_channel: slack_channel
  )
end

def get_default_name_of_app(build_variant)
  case @platform
  when :ios
    build_number = get_build_number(xcodeproj: "#{project_name}.xcodeproj")
    version = smf_get_version_number
    project_name = @smf_fastlane_config[:project][:project_name]
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

def get_default_name_of_pod
  podspec_path = @smf_fastlane_config[:build_variants][@smf_build_variant_sym][:podspec_path]
  version = read_podspec(path: podspec_path)["version"]
  pod_name = read_podspec(path: podspec_path)["name"]
  project_name = !@smf_fastlane_config[:project][:project_name].nil? ? @smf_fastlane_config[:project][:project_name] : pod_name
  "#{project_name} #{version}"
end