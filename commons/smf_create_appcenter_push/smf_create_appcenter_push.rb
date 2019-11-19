require "json"
require "signet/oauth_2/client"
require 'google/apis/drive_v2'

private_lane :smf_create_appcenter_push do |options|

	app_id = options[:app_id]
	app_owner = options[:app_owner]
	app_display_name = options[:app_display_name]

	keyfile = JSON.parse File.read ENV["FIREBASE_KEYFILE_SMF_HUB"]

	signet_options = {
  		token_credential_uri: "https://accounts.google.com/o/oauth2/token",
  		audience:             "https://accounts.google.com/o/oauth2/token",
  		scope:               ["https://www.googleapis.com/auth/cloud-platform"],
  		issuer:               keyfile["client_email"],
  		signing_key:          OpenSSL::PKey::RSA.new(keyfile["private_key"])
  	}

	signet = Signet::OAuth2::Client.new signet_options
	signet.fetch_access_token!

	UI.message("Build Signet and fetched access token")
	
	uri = URI('https://fcm.googleapis.com/v1/projects/705147538581/messages:send')
	https = Net::HTTP.new(uri.host,uri.port)
	https.use_ssl = true
	req = Net::HTTP::Post.new(uri)
	req['Authorization'] = "Bearer #{signet.access_token}"
	req['Content-Type'] = "application/json"
	
	req.body = {
		"message" => {
			"topic" => "#{app_owner}-#{app_id}",
			"notification" => {
				"body" => "Hey 👋, we just released #{app_display_name} for you 🚀. Feel free to check it out!",
				"title" => "📦 New Version of #{app_display_name} available"
			},
			"data" => {
	    		"app_id" => app_id
			}
		}
	}.to_json
	
	res = https.request(req)

	UI.message("Push Request has been send:\n#{res.body}")
end
