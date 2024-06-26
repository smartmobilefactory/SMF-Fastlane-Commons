private_lane :smf_android_upload_to_hockey do |options|

  apk_path = options[:apk_path]
  app_id = options[:app_id]

  raise("Cannot find the APK #{apk_path}") if apk_path.nil?

  UI.message('Upload Android app to Hockey.')
  hockey(
      api_token: ENV[$SMF_HOCKEYAPP_API_TOKEN_ENV_KEY],
      public_identifier: app_id,
      apk: apk_path,
      notify: "1",
      notes: smf_read_changelog
  )

end