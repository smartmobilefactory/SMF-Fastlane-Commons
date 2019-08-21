
private_lane :smf_create_dmg_from_app do |options|

  if @platform != :ios
    return
  end

  if ENV[$FASTLANE_PLATFORM_NAME_ENV_KEY] != "mac"
    raise "Wrong platform configuration: dmg's are only created for macOS apps."
  end

  app_path = smf_path_to_ipa_or_app

  # Create the dmg with the script and store it in the same directory as the app
  sh "#{@fastlane_commons_dir_path}/tools/create_dmg.sh -p #{app_path} -ci #{get_team_id}"
end

def smf_path_to_ipa_or_app

  escaped_filename = get_build_scheme.gsub(" ", "\ ")

  app_path = Pathname.getwd.dirname.to_s + "/build/#{escaped_filename}.app.zip"
  if ( ! File.exists?(app_path))
    app_path =  Pathname.getwd.dirname.to_s + "/build/#{escaped_filename}.app"
  end

  UI.message("Constructed path \"#{app_path}\" from filename \"#{escaped_filename}\"")

  unless File.exist?(app_path)
    app_path = lane_context[SharedValues::IPA_OUTPUT_PATH]

    UI.message("Using \"#{app_path}\" as app_path as no file exists at the constructed path.")
  end

  return app_path
end