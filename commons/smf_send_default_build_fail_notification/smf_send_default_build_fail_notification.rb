private_lane :smf_send_default_build_fail_notification do |options|

  branch = ENV['CHANGE_BRANCH']

  UI.message("smf_send_default_build_fail_notification")
  UI.message("Branch: #{branch}")

  if branch.nil? and !options[:slack_channel].nil?
    UI.message("Message will not be delivered, this seems to be a PR")
    return
  end

  message = options[:message]
  exception = options[:exception]
  name = options[:name]
  slack_channel = options[:slack_channel]

  smf_send_message(
      title: "💥 Failed to build #{name} 💥",
      message: message,
      exception: exception,
      type: 'error',
      slack_channel: slack_channel
  )
end