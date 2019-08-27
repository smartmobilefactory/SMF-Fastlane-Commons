private_lane :smf_upload_to_testflight do |options|

  username = !options[:username].nil? ? options[:username] : 'development@smfhq.com'
  itc_team_id = options[:itc_team_id]
  apple_id = !options[:apple_id].nil? ? options[:apple_id] : 'development@smfhq.com'
  skip_waiting_for_build_processing = options[:skip_waiting_for_build_processing]

  ENV["FASTLANE_ITC_TEAM_ID"] = itc_team_id

  UI.important("Uploading the build to Testflight.")
  upload_to_testflight(
      apple_id: apple_id,
      team_id: itc_team_id,
      username: username,
      skip_waiting_for_build_processing: skip_waiting_for_build_processing,
  )
end