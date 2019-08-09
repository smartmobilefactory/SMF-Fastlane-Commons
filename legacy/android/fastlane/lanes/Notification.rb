fastlane_require 'net/https'
fastlane_require 'uri'
fastlane_require 'json'

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
  https = Net::HTTP.new(uri.host, uri.port)
  https.use_ssl = true
  request = Net::HTTP::Post.new(uri.path, header)
  request.body = payload.to_json
  https.request(request)

end
