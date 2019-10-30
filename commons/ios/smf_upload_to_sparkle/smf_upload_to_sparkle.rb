private_lane :smf_upload_to_sparkle do |options|

  build_variant = options[:build_variant]

  app_path = smf_path_to_ipa_or_app(build_variant)
  app_path = app_path.sub('.app', '.dmg')
  update_dir = "#{smf_workspace_dir}/build/"

  release_notes = "#{ENV[$SMF_CHANGELOG_ENV_HTML_KEY]}"
  release_notes_name = "#{build_variant_config['scheme'.to_sym]}.html"
  File.write("#{update_dir}#{release_notes_name}", release_notes)

  if !File.exists?(app_path)
    raise("DMG file #{app_path} does not exit. Nothing to upload.")
  end

  sparkle = build_variant_config[:sparkle]

  app_name = "#{sparkle[:dmg_path]}#{build_variant_config[:scheme]}.dmg"
  user_name = sparkle[:upload_user]
  upload_url = sparkle[:upload_url]

  sh("scp -i #{ENV['CUSTOM_SPARKLE_PRIVATE_SSH_KEY']} #{update_dir}#{release_notes_name} '#{user_name}'@#{upload_url}:/#{sparkle[:dmg_path]}#{release_notes_name}")
  sh("scp -i #{ENV['CUSTOM_SPARKLE_PRIVATE_SSH_KEY']} #{app_path} '#{user_name}'@#{upload_url}:/#{app_name}")

  # Create appcast
  sparkle_private_key = ENV['CUSTOM_SPARKLE_SIGNING_KEY']

  sh "#{@fastlane_commons_dir_path}/tools/sparkle.sh #{ENV['LOGIN']} #{sparkle_private_key} #{update_dir} #{sparkle[:sparkle_version]} #{sparkle[:sparkle_signing_team]}"
  # Upload appcast
  appcast_xml = "#{update_dir}#{sparkle[:xml_name]}"
  appcast_upload_name = sparkle[:xml_name]
  sh("scp -i #{ENV['CUSTOM_SPARKLE_PRIVATE_SSH_KEY']} #{appcast_xml} '#{user_name}'@#{upload_url}:/#{sparkle[:dmg_path]}#{appcast_upload_name}")
end