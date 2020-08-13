private_lane :smf_notarize do |options|

  should_notarize = options[:should_notarize]

  if should_notarize != true || @platform != :macos
    UI.message("Notarization is not enabled for this build variant, or the platform is not macOS")
    next
  end

  dmg_path = options[:dmg_path]
  bundle_id = options[:bundle_id]
  username = options[:username]
  asc_provider = options[:asc_provider]
  custom_provider  = options[:custom_provider]

  unlock_keychain(path: "login.keychain", password: ENV[$KEYCHAIN_LOGIN_ENV_KEY])
  unlock_keychain(path: "jenkins.keychain", password: ENV[$KEYCHAIN_JENKINS_ENV_KEY])

  apple_id_account = CredentialsManager::AccountManager.new(user: "development@smfhq.com")
  ENV['FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD'] = apple_id_account.password

  notarize(
    package: dmg_path,
    bundle_id: bundle_id,
    username: username,
    asc_provider: custom_provider.nil? ? asc_provider : custom_provider,
    verbose: true
  )
end