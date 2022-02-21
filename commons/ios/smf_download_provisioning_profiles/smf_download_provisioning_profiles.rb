
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
  template_name = options[:template_name]
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
      template_name: template_name,
      force: force,
      platform: platform
    )

  elsif (!build_variant.match(/alpha/).nil? ||
        !build_variant.match(/beta/).nil? ||
        !build_variant.match(/example/).nil?) &&
        platform != 'macos'
          regex = /com\.smartmobilefactory\.enterprise/
          if bundle_identifier.match(regex) != nil

            UI.message("### DEBUG Extensions in 1: " + extension_suffixes.to_s)
            smf_download_provisioning_profile_using_match(
              app_identifier: app_identifier,
              type: 'enterprise',
              read_only: match_read_only,
              extensions_suffixes: extensions_suffixes,
              apple_id: apple_id,
              team_id: team_id,
              template_name: template_name,
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
  template_name = options[:template_name]

  force = options[:force]
  force = force.nil? ? !template_name.nil? : force

  platform = options[:platform]

  git_url = $FASTLANE_MATCH_REPO_URL

  UI.message("### DEBUG extension suffixes 2: " + extensions_suffixes.to_s)
  extension_identifiers = []
  if extensions_suffixes
    extensions_suffixes.each do |extension_suffix|
      extension_identifiers << "#{app_identifier}.#{extension_suffix}"
    end
  end

  UI.message("### DEBUG extension identifiers: " + extension_identifiers.to_s)
  if apple_id.nil? || team_id.nil?
    raise "Error username or team id for fastlane match is nil"
  end

  match(
    type: type,
    readonly: read_only,
    app_identifier: [app_identifier],
    username: apple_id,
    team_id: team_id,
    git_url: git_url,
    git_branch: team_id,
    keychain_name: "jenkins.keychain",
    keychain_password: ENV[$KEYCHAIN_JENKINS_ENV_KEY],
    template_name: template_name,
    force: force,
    platform: platform
  )
  UI.message("### DEBUG extension identifiers empty: " + extension_identifiers.empty?)
  match(
    type: type,
    readonly: read_only,
    app_identifier: extension_identifiers,
    username: apple_id,
    team_id: team_id,
    git_url: git_url,
    git_branch: team_id,
    keychain_name: "jenkins.keychain",
    keychain_password: ENV[$KEYCHAIN_JENKINS_ENV_KEY],
    force: force,
    platform: platform
  ) unless extension_identifiers.empty?
end