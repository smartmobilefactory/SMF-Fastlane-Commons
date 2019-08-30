fastlane_require 'net/https'
fastlane_require 'uri'
fastlane_require 'json'

###################################
### smf_send_ios_hockey_app_apn ###
###################################

desc "Send a Push Notification through OneSignal to the SMF HockeyApp"
private_lane :smf_send_ios_hockey_app_apn do |options|

  UI.important("Sending APN to the SMF HockeyApps which inform the users that a new version of favorited apps is built.")

  # Variables
  hockeyapp_id = @smf_fastlane_config[:build_variants][@smf_build_variant_sym][:hockeyapp_id]

  # Create valid URI
  uri = URI.parse('https://onesignal.com/api/v1/notifications')

  # Authentification Header
  header = {
    'Content-Type' => 'application/json; charset=utf-8',
    'Authorization' => "Basic #{ENV[$SMF_ONE_SIGNAL_BASIC_AUTH_ENV_KEY]}" # OneSignal User AuthKey REST API
  }

  # Notification Payload
  payload = {
    'app_ids' => ['f809f1b9-e7ae-4d64-946b-66db65daf360', '5cd4e388-10ad-4bd7-b0a0-acd8a25420a7'], # OneSignal App IDs (ALPHA & BETA)
    'content_available' => 'true',
    'mutable_content' => 'true',
    'isIos' => 'true',
    'ios_category' => 'com.usernotifications.app_update', # Remote Notification Category.
    'filters' => [
      {
        'field' => 'tag',
        'relation' => '=',
        'key' => hockeyapp_id,
        'value' => 'com.usernotifications.app_update'
      }
    ],
    'data' => {
      'HockeyAppId' => hockeyapp_id
    }
  }

  # Create and send a POST request
  https = Net::HTTP.new(uri.host,uri.port)
  https.use_ssl = true
  request = Net::HTTP::Post.new(uri.path, header)
  request.body = payload.to_json
  https.request(request)

end

##############
### HELPER ###
##############

def smf_default_notification_release_title
  release_title = nil
  if smf_is_build_variant_a_pod == true
    release_title = smf_default_pod_notification_release_title
  elsif smf_is_build_variant_a_decoupled_ui_test == true
    release_title = smf_default_decoupled_ui_test_notification_name_title
  else
    release_title = smf_default_app_notification_release_title
  end
  return release_title
end

def smf_default_app_notification_release_title

  # Variables
  project_name = @smf_fastlane_config[:project][:project_name]
  build_variant = @smf_build_variant

  build_number = get_build_number(xcodeproj: "#{project_name}.xcodeproj")
  version = get_version_number(
      xcodeproj: "#{get_project_name}.xcodeproj",
      target: (get_target != nil ? get_target : get_build_scheme)
  )
  return "#{project_name} #{build_variant.upcase} #{version} (#{build_number})"
end

def smf_default_pod_notification_release_title

  # Variables
  podspec_path = @smf_fastlane_config[:build_variants][@smf_build_variant_sym][:podspec_path]
  version = read_podspec(path: podspec_path)["version"]
  pod_name = read_podspec(path: podspec_path)["name"]

  # Project name
  project_name = @smf_fastlane_config[:project][:project_name]
  project_name = (project_name.nil? ? pod_name : project_name)

  return "#{project_name} #{version}"
end

def smf_default_decoupled_ui_test_notification_name_title
  return "#{ENV[$SMF_UI_TEST_REPORT_NAME_FOR_NOTIFICATIONS]}"
end
