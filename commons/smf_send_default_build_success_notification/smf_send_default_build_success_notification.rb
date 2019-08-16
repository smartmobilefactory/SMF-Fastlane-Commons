private_lane :smf_send_default_build_success_notification do |options|

  build_variant = options[:build_variant]
  is_pod = !options[:is_pod].nil? ? options[:is_pod] : false
  name = options[:name]
  slack_channel = @smf_fastlane_config[:project][:slack_channel]
  # Collect the changelog (again) in case the build job failed before the former changelog collecting
  smf_git_changelog(build_variant: build_variant, is_pod: is_pod) if ENV[$SMF_CHANGELOG_ENV_KEY].nil?

  smf_send_message(
      title: "🎉🛠 Successfully built #{name} 🛠🎉",
      type: 'success',
      message: ENV[$SMF_CHANGELOG_ENV_KEY],
      slack_channel: slack_channel
  )
end