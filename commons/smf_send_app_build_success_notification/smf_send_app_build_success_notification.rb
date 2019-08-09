desc "Post to a Slack room if the build was successful"
private_lane :smf_send_app_build_success_notification do |options|

  build_variant = options[:build_variant]

  case @platform
  when :ios
    build_number = get_build_number(xcodeproj: "#{project_name}.xcodeproj")
    version = smf_get_version_number
    project_name = @smf_fastlane_config[:project][:project_name]
    name = "#{project_name} #{build_variant.upcase} #{version} (#{build_number})"
  when :android
    project_name = !@smf_fastlane_config[:project][:name].nil? ? @smf_fastlane_config[:project][:name] : ENV["PROJECT_NAME"]
    name = "#{project_name} #{build_variant} (Build #{ENV["next_version_code"]})"
  when :flutter
    UI.message('Notification for flutter is not implemented yet')
  else
    UI.message("There is no platform \"#{@platform}\", exiting...")
    raise 'Unknown platform'
  end

  smf_default_build_success_notification("🎉🛠 Successfully built #{name} 🛠🎉", build_variant)
end
