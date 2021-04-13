
private_lane :smf_send_deprecation_warning do |options|
  name = @smf_fastlane_config.dig(:project, :project_name)
  slack_channel = @smf_fastlane_config.dig(:project, :slack_channel)

  message = options[:message]
  title = options[:title]

  smf_send_message(
    title: "⚠️ #{name} DEPRECATION WARNING: #{title} ⚠️",
    message: message,
    type: 'error',
    slack_channel: slack_channel
  )
end