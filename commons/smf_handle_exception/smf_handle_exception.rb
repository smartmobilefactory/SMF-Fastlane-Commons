desc "Handle the exception"
private_lane :smf_handle_exception do |options|
  UI.important("Handling the build job exception")

  message = options[:message]
  exception = options[:exception]
  name = options[:name]
  slack_channel = options[:slack_channel]

  smf_send_default_build_fail_notification(
      name: name,
      message: message,
      exception: exception
  )

  if !slack_channel.nil?
    smf_send_default_build_fail_notification(
        name: name,
        message: message,
        exception: exception,
        slack_channel: slack_channel
    )
  end
end
