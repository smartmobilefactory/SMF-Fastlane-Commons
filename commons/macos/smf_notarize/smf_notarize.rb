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

  smf_setup_correct_xcode_executable_for_build(required_xcode_version: "11.2.1")

  if smf_is_keychain_enabled
    unlock_keychain(path: "login.keychain", password: ENV[$KEYCHAIN_LOGIN_ENV_KEY])
    unlock_keychain(path: "jenkins.keychain", password: ENV[$KEYCHAIN_JENKINS_ENV_KEY])
  end

  notarize(
    package: dmg_path,
    bundle_id: bundle_id,
    username: username,
    asc_provider: custom_provider.nil? ? asc_provider : custom_provider,
    verbose: true
  )
end