private_lane :smf_send_default_build_fail_notification do |options|

  message = options[:message]
  exception = options[:exception]
  name = options[:name]
  slack_channel = @smf_fastlane_config[:project][:slack_channel]

  smf_send_message(
      title: "💥 Failed to build #{name} 💥",
      message: message,
      exception: exception,
      type: 'error',
      slack_channel: slack_channel
  )
end