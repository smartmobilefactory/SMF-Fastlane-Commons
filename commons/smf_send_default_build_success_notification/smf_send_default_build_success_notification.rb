private_lane :smf_send_default_build_success_notification do |options|

  name = options[:name]
  slack_channel = options[:slack_channel]

  changelog = smf_read_changelog(type: :slack_markdown)

  smf_send_message(
      title: "🎉🛠 Successfully built #{name} 🛠🎉",
      type: 'success',
      message: changelog,
      slack_channel: slack_channel
  )
end