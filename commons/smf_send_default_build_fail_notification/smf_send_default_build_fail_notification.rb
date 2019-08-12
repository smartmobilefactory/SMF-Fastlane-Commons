private_lane :smf_default_build_fail_notification do |options|

  message = options[:message]
  exception = options[:exception]
  build_variant = options[:build_variant]
  slack_channel = @smf_fastlane_config[:project][:slack_channel]

  # Collect the changelog (again) in case the build job failed before the former changelog collecting
  smf_git_changelog(build_variant: build_variant) if ENV[$SMF_CHANGELOG_ENV_KEY].nil?

  name = !@smf_fastlane_config[:build_variants][@smf_build_variant_sym][:podspec_path].nil? ? get_default_name_of_pod : get_default_name_of_app(build_variant)

  smf_send_message(
      title: "💥 Failed to build #{name} 💥",
      message: message,
      exception: exception,
      type: 'error',
      slack_channel: slack_channel
  )
end