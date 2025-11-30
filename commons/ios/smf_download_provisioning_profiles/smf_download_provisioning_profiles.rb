
private_lane :smf_download_provisioning_profiles do |options|

  # Parameters
  team_id = options[:team_id]
  apple_id = options[:apple_id]
  use_wildcard_signing = options[:use_wildcard_signing]
  bundle_identifier = options[:bundle_identifier]
  use_default_match_config = options[:use_default_match_config]
  match_read_only = options[:match_read_only]
  match_type = options[:match_type]
  extensions_suffixes = options[:extensions_suffixes]
  build_variant = options[:build_variant]
  # template_name = options[:template_name] # Removed due to Apple API deprecation
  force = options[:force]
  platform = options[:platform].nil? ? 'ios' : options[:platform]

  team_id(team_id)

  if smf_is_keychain_enabled
    unlock_keychain(path: 'login.keychain', password: ENV[$KEYCHAIN_LOGIN_ENV_KEY])
    unlock_keychain(path: 'jenkins.keychain', password: ENV[$KEYCHAIN_JENKINS_ENV_KEY])
  end

  app_identifier = (use_wildcard_signing == true ? '*' : bundle_identifier)
  allowed_types = ['appstore', 'adhoc', 'development', 'enterprise', 'developer_id']

  if use_default_match_config == false
    if (match_read_only == nil || allowed_types.include?(match_type) == false)
      raise 'The fastlane match entries in the Config.json file are incomplete. Set `readonly` and `type` for the `match` Key.'
    end

    smf_download_provisioning_profile_using_match(
      app_identifier: app_identifier,
      type: match_type,
      read_only: match_read_only,
      extensions_suffixes: extensions_suffixes,
      apple_id: apple_id,
      team_id: team_id,
      # template_name: template_name, # Removed due to Apple API deprecation
      force: force,
      platform: platform
    )

  elsif (!build_variant.match(/alpha/).nil? ||
        !build_variant.match(/beta/).nil? ||
        !build_variant.match(/example/).nil?) &&
        platform != 'macos'
          regex = /com\.smartmobilefactory\.enterprise/
          if bundle_identifier.match(regex) != nil
            smf_download_provisioning_profile_using_match(
              app_identifier: app_identifier,
              type: 'enterprise',
              read_only: match_read_only,
              extensions_suffixes: extensions_suffixes,
              apple_id: apple_id,
              team_id: team_id,
              # template_name: template_name, # Removed due to Apple API deprecation
              force: force,
              platform: 'ios'
            )
          end
  end

end

private_lane :smf_download_provisioning_profile_using_match do |options|
  app_identifier = options[:app_identifier]
  type = options[:type]
  read_only = type.nil? ? false : options[:read_only]
  extensions_suffixes = options[:extensions_suffixes]
  apple_id = options[:apple_id]
  team_id = options[:team_id]

  force = options[:force]
  force = force.nil? ? false : force

  platform = options[:platform]

  git_url = $FASTLANE_MATCH_REPO_URL

  extension_identifiers = []
  if extensions_suffixes
    extensions_suffixes.each do |extension_suffix|
      extension_identifiers << "#{app_identifier}.#{extension_suffix}"
    end
  end

  if apple_id.nil? || team_id.nil?
    raise "Error username or team id for fastlane match is nil"
  end

  # Create App Store Connect API key if environment variables are available
  api_key = nil
  
  # Debug: Comprehensive environment variable analysis
  UI.important("=== API KEY ENVIRONMENT VARIABLES DEBUG ===")

  # Our expected variables
  UI.message("APP_STORE_CONNECT_API_KEY_ID: #{ENV['APP_STORE_CONNECT_API_KEY_ID'] ? 'SET' : 'NOT SET'}")
  UI.message("APP_STORE_CONNECT_API_KEY_ISSUER_ID: #{ENV['APP_STORE_CONNECT_API_KEY_ISSUER_ID'] ? 'SET' : 'NOT SET'}")
  UI.message("APP_STORE_CONNECT_API_KEY_PATH: #{ENV['APP_STORE_CONNECT_API_KEY_PATH'] ? 'SET' : 'NOT SET'}")

  # Potential conflicting Fastlane variables
  UI.message("FASTLANE_API_KEY: #{ENV['FASTLANE_API_KEY'] ? 'SET' : 'NOT SET'}")
  UI.message("FASTLANE_API_KEY_PATH: #{ENV['FASTLANE_API_KEY_PATH'] ? 'SET' : 'NOT SET'}")
  UI.message("APP_STORE_CONNECT_API_KEY: #{ENV['APP_STORE_CONNECT_API_KEY'] ? 'SET' : 'NOT SET'}")
  UI.message("APP_STORE_CONNECT_API_KEY_KEY_FILEPATH: #{ENV['APP_STORE_CONNECT_API_KEY_KEY_FILEPATH'] ? 'SET' : 'NOT SET'}")

  # Search for any environment variable containing 'API_KEY'
  api_key_vars = ENV.select { |key, value| key.upcase.include?('API_KEY') && !value.nil? && !value.empty? }
  if api_key_vars.any?
    UI.important("All API_KEY related environment variables found:")
    api_key_vars.each do |key, value|
      # Show first 20 chars of value for security, but indicate if it's set
      safe_value = value.length > 20 ? "#{value[0..19]}... (#{value.length} chars)" : value
      UI.message("  #{key}: #{safe_value}")
    end
  else
    UI.message("No API_KEY environment variables found")
  end

  # Jenkins specific variables that might interfere
  jenkins_vars = %w[BUILD_ID BUILD_NUMBER JOB_NAME JENKINS_URL WORKSPACE]
  UI.message("Jenkins context: #{jenkins_vars.map { |var| "#{var}=#{ENV[var]}" }.select { |s| !s.end_with?('=') }.join(', ')}")

  UI.important("=== END DEBUG ===")

  
  if ENV['APP_STORE_CONNECT_API_KEY_ID'] && ENV['APP_STORE_CONNECT_API_KEY_ISSUER_ID'] && ENV['APP_STORE_CONNECT_API_KEY_PATH']
    UI.message('Using App Store Connect API key for provisioning profiles')
    api_key = app_store_connect_api_key(
      key_id: ENV['APP_STORE_CONNECT_API_KEY_ID'],
      issuer_id: ENV['APP_STORE_CONNECT_API_KEY_ISSUER_ID'],
      key_filepath: ENV['APP_STORE_CONNECT_API_KEY_PATH'],
      duration: 1200
    )
  else
    UI.message('Using username/password authentication for provisioning profiles (fallback)')
  end

  # Debug: Log exact match parameters
  UI.important("=== MATCH CALL DEBUG ===")
  UI.message("Match parameters being passed:")
  UI.message("  type: #{type}")
  UI.message("  readonly: #{read_only}")
  UI.message("  app_identifier: #{[app_identifier]}")
  UI.message("  api_key: #{api_key ? 'API_KEY_OBJECT_SET' : 'nil'}")
  UI.message("  username: #{api_key ? 'nil (using api_key)' : apple_id}")
  UI.message("  team_id: #{team_id}")
  UI.message("  api_key_path: NOT_EXPLICITLY_SET")
  UI.message("  platform: #{platform}")
  UI.important("=== END MATCH DEBUG ===")

  # WORKAROUND: Prevent Fastlane from automatically setting api_key_path
  # when APP_STORE_CONNECT_API_KEY_PATH env variable is present
  # This avoids conflict between api_key (object) and api_key_path (string)
  if api_key
    UI.message("Temporarily clearing APP_STORE_CONNECT_API_KEY_PATH to prevent auto api_key_path setting")
    api_key_path_backup = ENV['APP_STORE_CONNECT_API_KEY_PATH']
    ENV['APP_STORE_CONNECT_API_KEY_PATH'] = nil
  end

  match(
    type: type,
    readonly: read_only,
    app_identifier: [app_identifier],
    api_key: api_key,
    username: api_key ? nil : apple_id,
    team_id: team_id,
    git_url: git_url,
    git_branch: team_id,
    keychain_name: "jenkins.keychain",
    keychain_password: ENV[$KEYCHAIN_JENKINS_ENV_KEY],
    force: force,
    platform: platform
  )

  # Restore environment variable after match call
  if api_key && api_key_path_backup
    UI.message("Restoring APP_STORE_CONNECT_API_KEY_PATH environment variable")
    ENV['APP_STORE_CONNECT_API_KEY_PATH'] = api_key_path_backup
  end

  # Apply same workaround for extension profiles
  unless extension_identifiers.empty?
    if api_key
      UI.message("Temporarily clearing APP_STORE_CONNECT_API_KEY_PATH for extension profiles")
      api_key_path_backup = ENV['APP_STORE_CONNECT_API_KEY_PATH']
      ENV['APP_STORE_CONNECT_API_KEY_PATH'] = nil
    end

    match(
      type: type,
      readonly: read_only,
      app_identifier: extension_identifiers,
      api_key: api_key,
      username: api_key ? nil : apple_id,
      team_id: team_id,
      git_url: git_url,
      git_branch: team_id,
      keychain_name: "jenkins.keychain",
      keychain_password: ENV[$KEYCHAIN_JENKINS_ENV_KEY],
      force: force,
      platform: platform
    )

    if api_key && api_key_path_backup
      UI.message("Restoring APP_STORE_CONNECT_API_KEY_PATH after extension profiles")
      ENV['APP_STORE_CONNECT_API_KEY_PATH'] = api_key_path_backup
    end
  end
end