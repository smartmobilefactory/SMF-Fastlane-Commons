private_lane :smf_notarize do |options|

  should_notarize = options[:should_notarize]

  if should_notarize != true
    UI.message("Notarization is not enabled for this build variant, or the platform is not macOS")
    next
  end

  dmg_path = options[:dmg_path]
  bundle_id = options[:bundle_id]
  username = options[:username]
  asc_provider = options[:asc_provider]
  custom_provider = options[:custom_provider]

  # Create App Store Connect API key if environment variables are available
  api_key = nil
  if ENV['APP_STORE_CONNECT_API_KEY_ID'] && ENV['APP_STORE_CONNECT_API_KEY_ISSUER_ID'] && ENV['APP_STORE_CONNECT_API_KEY_PATH']
    UI.message('Using App Store Connect API key for notarization')
    api_key = app_store_connect_api_key(
      key_id: ENV['APP_STORE_CONNECT_API_KEY_ID'],
      issuer_id: ENV['APP_STORE_CONNECT_API_KEY_ISSUER_ID'],
      key_filepath: ENV['APP_STORE_CONNECT_API_KEY_PATH'],
      duration: 1200,
      in_house: false
    )
  else
    UI.message('Using username/password authentication for notarization (fallback)')
  end


  notarize(
    package: dmg_path,
    bundle_id: bundle_id,
    api_key: api_key,
    username: api_key ? nil : username,
    asc_provider: custom_provider.nil? ? asc_provider : custom_provider
  )
end