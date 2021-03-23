
# Wrapper lane so android projects keep working after the newly implemented
# phrase sync lane. Should be removed as soon as all android projects are migrated.

private_lane :sync_with_phrase_app do |options|
  message = '⚠️⚠️⚠️️The lane/action "sync_with_phrase_app" is deprecated, please use "smf_sync_with_phrase"! ⚠️⚠️⚠️'
  UI.message(message)

  name = @smf_fastlane_config.dig(:project, :project_name)
  slack_channel = @smf_fastlane_config.dig(:project, :slack_channel)

  smf_send_message(
    title: "⚠️ WARNING: #{name} uses deprecated phraseapp action ⚠️",
    message: message,
    type: 'error',
    slack_channel: slack_channel
  )

  smf_sync_with_phrase(options)
end