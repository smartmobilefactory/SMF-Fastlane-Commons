fastlane_require 'net/https'
fastlane_require 'uri'
fastlane_require 'json'

##############################
### smf_notify_via_slack ###
##############################

desc "Post to a Slack room if the build was successful"
private_lane :smf_notify_build_success do |options|

  build_variant = ENV["BUILD_VARIANT"]

  changelog = ENV["CHANGELOG"]

  if changelog.nil?
    changelog = "No changelog provided"
  elsif changelog.length > 9000
    changelog = changelog[0..9000]
  end

  smf_send_notification(
    success: true,
    message:"*🎉 Successfully released #{project_name()} #{build_variant} (Build #{ENV["next_version_code"]}) 🎉*\n```#{changelog}```"
  )
end

desc "Notify that build failed"
private_lane :smf_notify_build_failed do |options|
  exception = options[:exception]
  build_variant = ENV["BUILD_VARIANT"]
  smf_send_notification(
    success: false,
    message: "*😢 Failed to build and release #{project_name()} #{build_variant} 😢* \n```#{exception}```"
  )
end

desc "Sends a notification to the prefered tool"
private_lane :smf_send_notification do |options|
  slack_url = "https://hooks.slack.com/services/" + ENV["SMF_SLACK_URL_IDENTIFIER"]
  message = options[:message]
  success = options[:success] || true
  config = load_config()
  slack_channel = ENV["SLACK_CHANNEL"]
  if config
    slack_channel = config["project"]["slack_channel"]
  end
  if slack_channel
    slack_channel = "\#" + URI.escape(slack_channel)
    slack(
      slack_url: slack_url,
      message: message,
      channel: slack_channel,
      success: success,
      default_payloads: []
    )
  else
    slack(
      slack_url: slack_url,
      message:"*Slackchannel not set in Config.json or as Environment variable SLACK_CHANNEL in project #{project_name()}. Please fix!*",
      channel: "\#android",
      success: false,
      default_payloads: []
    )
  end
end

###########################
### smf_notify_via_mail ###
###########################


desc "Send emails to all collaborators who worked on the project since the last build to inform about successfully or failing build jobs."
private_lane :smf_notify_via_mail do |options|
  # not in use anymore. keep lane to be compatible
end

###################################
### smf_send_ios_hockey_app_apn ###
###################################

# options: hockeyapp_id (String)

desc "Send a Push Notification through OneSignal to the SMF HockeyApp"
private_lane :smf_notify_app_uploaded do |options|

  UI.important("Send Push Notification")

  # Read options parameter
  hockey_app_id = options[:hockeyapp_id]

  # Create valid URI
  uri = URI.parse('https://onesignal.com/api/v1/notifications')

  # Authentification Header
  header = {
    'Content-Type' => 'application/json; charset=utf-8',
    'Authorization' => 'Basic ' + ENV["ONESIGNAL_SMF_API_KEY"] # OneSignal User AuthKey REST API
  }

  # Notification Payload
  payload = {
    'app_ids': ['f809f1b9-e7ae-4d64-946b-66db65daf360', '5cd4e388-10ad-4bd7-b0a0-acd8a25420a7'], # OneSignal App IDs (ALPHA & BETA)
    'content_available': 'true',
    'mutable_content': 'true',
    'isIos': 'true',
    'ios_category': 'com.usernotifications.app_update', # Remote Notification Category.
    'filters': [
      {
        'field': 'tag',
        'relation': '=',
        'key': hockey_app_id,
        'value': 'com.usernotifications.app_update'
      }
    ],
    'data': {
      'HockeyAppId': hockey_app_id
    }
  }

  # Create and send a POST request
  https = Net::HTTP.new(uri.host,uri.port)
  https.use_ssl = true
  request = Net::HTTP::Post.new(uri.path, header)
  request.body = payload.to_json
  https.request(request)

end
