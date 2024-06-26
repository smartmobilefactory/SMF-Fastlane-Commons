
private_lane :smf_create_dmg_from_app do |options|

  team_id = options[:team_id]
  code_signing_identity = options[:code_signing_identity]
  dmg_template_path = options[:dmg_template_path]

  signing_id = code_signing_identity.nil? ? team_id : code_signing_identity

  app_path = smf_path_to_app_file

  raise 'Error, .app path could not be found.' if app_path.nil?

  # Create the dmg with the script and store it in the same directory as the app
  if dmg_template_path.nil?
  sh "#{@fastlane_commons_dir_path}/commons/ios/smf_create_dmg_from_app/create_dmg.sh -p #{app_path.shellescape} -ci '#{signing_id}'"
  else
  UI.message("Will use DMG template at #{dmg_template_path} to generate the DMG")
  sh "#{@fastlane_commons_dir_path}/commons/ios/smf_create_dmg_from_app/create_dmg.sh -p #{app_path.shellescape} -ci '#{signing_id}' -t #{dmg_template_path.shellescape}"  
  end

  UI.message("Created dmg at: #{app_path.gsub('.app', '.dmg')}")

  app_path.gsub('.app', '.dmg')
end