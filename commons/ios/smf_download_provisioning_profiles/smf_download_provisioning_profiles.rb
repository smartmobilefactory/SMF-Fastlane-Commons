
private_lane :smf_download_provisioning_profiles do |options|

  if @platform != :ios
    return
  end

  if ENV[$FASTLANE_PLATFORM_NAME_ENV_KEY] == "mac"
    UI.message("Skipping fastlane match, because it doesn't support mac apps.")
    return
  end

  team_id(get_team_id)

  if smf_is_keychain_enabled
    unlock_keychain(path: "login.keychain", password: ENV[$KEYCHAIN_LOGIN_ENV_KEY])
    unlock_keychain(path: "jenkins.keychain", password: ENV[$KEYCHAIN_JENKINS_ENV_KEY])
  end

  app_identifier = (get_use_wildcard_signing == true ? "*" : get_bundle_identifier)
  allowed_types = ["appstore", "adhoc", "development", "enterprise"]

  if (get_match_config_read_only == nil || allowed_types.include?(get_match_config_type) == false)
    raise "The fastlane match entries in the Config.json file are incomplete. Set `readonly` and `type` for the `match`-Key."
  end

  if match_config == nil && (@smf_build_variant.match(/alpha/) != nil || @smf_build_variant.match(/beta/) != nil || @smf_build_variant.match(/example/) != nil)
    regex = /com\.smartmobilefactory\.enterprise/
    if bundle_identifier.match(regex) != nil
      smf_download_provisioning_profile_using_match(app_identifier, "enterprise")
    end
  else
    smf_download_provisioning_profile_using_match(app_identifier)
  end
end

def smf_download_provisioning_profile_using_match(app_identifier, type = nil)
  type = type == nil ? get_match_config_type: type
  read_only = (type == nil ? get_match_config_read_only : false)
  extensions_suffixes = get_extension_suffixes

  username = get_apple_id
  team_id = get_team_id
  git_url = $FASTLANE_MATCH_REPO_URL
  identifiers = [app_identifier]

  if extensions_suffixes
    for extension_suffix in extensions_suffixes do
      identifiers << "#{app_identifier}.#{extension_suffix}"
    end
  end

  if username.nil? || team_id.nil?
    raise "Error username or team id for fastlane match is nil"
  end

  match(type: type, readonly: read_only, app_identifier: identifiers, username: username, team_id: team_id, git_url: git_url, git_branch: team_id, keychain_name: "jenkins.keychain", keychain_password: ENV[$KEYCHAIN_JENKINS_ENV_KEY])
end