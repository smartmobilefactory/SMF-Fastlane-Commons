
private_lane :smf_create_dmg_from_app do |options|

  team_id = options[:team_id]
  scheme = options[:scheme]

  app_path = smf_path_to_ipa_or_app(scheme)

  # Create the dmg with the script and store it in the same directory as the app
  sh "##{@fastlane_commons_dir_path}/commons/ios/smf_create_dmg_from_app/create_dmg.sh -p #{app_path} -ci #{team_id}"

  UI.message("Created dmg at: #{app_path.gsub('.app', '.dmg')}")

  app_path.gsub('.app', '.dmg')
end