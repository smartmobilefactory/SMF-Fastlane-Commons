private_lane :smf_upload_to_testflight do |options|

  username = options[:username]
  skip_waiting_for_build_processing = options[:skip_waiting_for_build_processing]
  UI.important("Uploading the build to Testflight.")

  upload_to_testflight(
      username: username,
      skip_waiting_for_build_processing: skip_waiting_for_build_processing,
  )
end