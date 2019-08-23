private_lane :smf_generate_temporary_appfile do |options|

  build_variant = options[:build_variant]

  apple_id = get_apple_id(build_variant)
  team_id = get_team_id(build_variant)

  if apple_id.nil?
    UI.important('Could not find the apple_id for this build variant, will use development@smfhq.com. Please update your Config.json.')
  else
    UI.message("Found apple_id: #{apple_id} in Config.json.")
  end

  # If there's no apple_id setting, use the default development@smfhq.com
  apple_id = !apple_id.nil? ? apple_id : 'development@smfhq.com'

  appfile_content = "apple_id \"#{apple_id}\""

  appfile_content += "\nteam_id \"#{team_id}\""

  File.write("#{smf_workspace_dir}/fastlane/Appfile", appfile_content)
end
