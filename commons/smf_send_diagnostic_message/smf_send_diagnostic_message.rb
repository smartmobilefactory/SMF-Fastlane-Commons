require 'json'

DIAGNOSTIC_CHANNEL_NAME = 'ci-diagnostic-messages'

private_lane :smf_send_diagnostic_message do |options|

  title = options[:title]
  message = options[:message]

  smf_send_message(
    title: title,
    message: message,
    slack_channel: DIAGNOSTIC_CHANNEL_NAME,
  )
end