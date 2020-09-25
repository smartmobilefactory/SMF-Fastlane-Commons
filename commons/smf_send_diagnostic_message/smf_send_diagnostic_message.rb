require 'json'

private_lane :smf_send_diagnostic_message do |options|

  title = options[:title]
  message = options[:message]

  smf_send_message(
    title: title,
    message: message,
    slack_channel: $SMF_CI_DIAGNOSTIC_CHANNEL,
  )
end