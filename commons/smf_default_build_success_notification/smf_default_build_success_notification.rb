def smf_default_build_success_notification(title)

  build_variant = options[:build_variant]
  slack_channel = @smf_fastlane_config[:project][:slack_channel]

  # Collect the changelog (again) in case the build job failed before the former changelog collecting
  smf_git_changelog(build_variant: build_variant) if ENV[$SMF_CHANGELOG_ENV_KEY].nil?

  smf_send_message(
      title: "🎉🛠 Successfully built #{project_name} #{version} 🛠🎉",
      type: 'success',
      message: ENV[$SMF_CHANGELOG_ENV_KEY],
      slack_channel: slack_channel
  )
end