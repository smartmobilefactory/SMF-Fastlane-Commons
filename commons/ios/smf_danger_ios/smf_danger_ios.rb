private_lane :smf_danger_ios do |options|

  danger_file_path = "#{@fastlane_commons_dir_path}/commons/ios/smf_danger_ios/Dangerfile"
  if File.file?(danger_file_path)

    ENV["BUILD_VARIANT"] = options[:build_variant]
    ENV["FASTLANE_CONFIG_PATH"] = "#{@fastlane_commons_dir_path}/../Config.json"
    ENV["FASTLANE_COMMONS_FOLDER"] = @fastlane_commons_dir_path

    danger(
        danger_id: options[:build_variant],
        dangerfile: danger_file_path,
        github_api_token: ENV[$SMF_GITHUB_TOKEN_ENV_KEY]
    )
  else
    UI.important("There was no Dangerfile at #{danger_file_path}, not running danger at all!")
  end
end