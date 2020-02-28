private_lane :smf_android_upload_to_appcenter do |options|

  apk_path = options[:apk_path]
  aab_path = options[:aab_path]
  app_id = options[:app_id]
  destinations = options[:destinations]

  app_id, app_name, owner_name, owner_id = smf_appcenter_get_app_details(app_id)
  smf_upload_to_appcenter_precheck(
    app_name: app_name,
    owner_name: owner_name,
    destinations: destinations
  )

  UI.important('APK path is null.') if apk_path.nil?
  UI.important("AAB path is null.") if aab_path.nil?

  UI.message('Upload android app to AppCenter.')
  if !aab_path.nil?
    appcenter_upload(
        api_token: ENV[$SMF_APPCENTER_API_TOKEN_ENV_KEY],
        owner_name: owner_name,
        app_name: app_name,
        file: aab_path,
        destination_type: 'store',
        destinations: destinations,
        notify_testers: true,
        release_notes: smf_read_changelog
    )
  else
    appcenter_upload(
        api_token: ENV[$SMF_APPCENTER_API_TOKEN_ENV_KEY],
        owner_name: owner_name,
        app_name: app_name,
        file: apk_path,
        destinations: destinations,
        notify_testers: true,
        release_notes: smf_read_changelog
    )
  end

  smf_appcenter_notify_destination_groups(app_id, app_name, owner_name, destinations)
end
