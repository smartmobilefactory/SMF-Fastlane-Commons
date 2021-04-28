
private_lane :smf_send_deprecation_warning do |options|
  name = @smf_fastlane_config.dig(:project, :project_name)
  slack_channel = @smf_fastlane_config.dig(:project, :slack_channel)

  message = options[:message]
  title = options[:title]
  estimated_time = options[:estimated_time]
  requirements = options[:requirements]

  if estimated_time
    message += "\n⏱ This migration takes approximately: #{estimated_time}"
  end

  if requirements
    requirements_section = "\n🔐 Requirements"

    requirements.each do |requirement|
      requirements_section += "\n‣ #{requirement}"
    end

    message += requirements_section
  end

  smf_send_message(
    title: "⚠️ #{name} DEPRECATION WARNING: #{title} ⚠️",
    message: message,
    type: 'error',
    slack_channel: slack_channel
  )
end