private_lane :smf_upload_to_testflight do |options|

  username = !options[:username].nil? ? options[:username] : 'development@smfhq.com'
  team_id = !options[:team_id].nil? ? options[:team_id] : 'development@smfhq.com'
  skip_waiting_for_build_processing = options[:skip_waiting_for_build_processing]
  UI.important("Uploading the build to Testflight.")

  upload_to_testflight(
      team_id: team_id,
      username: username,
      skip_waiting_for_build_processing: skip_waiting_for_build_processing,
  )
end