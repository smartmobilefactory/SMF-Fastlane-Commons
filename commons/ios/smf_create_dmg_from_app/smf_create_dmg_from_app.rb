
private_lane :smf_create_dmg_from_app do |options|

  build_variant = options[:build_variant]
  team_id = options[:team_id]
  code_signing_identity = options[:code_signing_identity]

  signing_id = code_signing_identity.nil? ? team_id : code_signing_identity

  app_path = smf_path_to_ipa_or_app(build_variant)

  # Create the dmg with the script and store it in the same directory as the app
  sh "#{@fastlane_commons_dir_path}/commons/ios/smf_create_dmg_from_app/create_dmg.sh -p #{app_path} -ci '#{signing_id}'"


  UI.message("Created dmg at: #{app_path.gsub('.app', '.dmg')}")

  app_path.gsub('.app', '.dmg')
end