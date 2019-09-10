
private_lane :smf_create_dmg_from_app do |options|

  team_id = options[:team_id]
  build_scheme = options[:build_scheme]

  if ENV[$FASTLANE_PLATFORM_NAME_ENV_KEY] != "mac"
    raise "Wrong platform configuration: dmg's are only created for macOS apps."
  end

  app_path = smf_path_to_ipa_or_app(build_scheme)

  # Create the dmg with the script and store it in the same directory as the app
  sh "##{@fastlane_commons_dir_path}/commons/ios/smf_create_dmg_from_app/create_dmg.sh -p #{app_path} -ci #{team_id}"
end