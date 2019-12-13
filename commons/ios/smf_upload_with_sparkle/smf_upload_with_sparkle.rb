private_lane :smf_upload_with_sparkle do |options|

  build_variant = options[:build_variant]
  scheme = options[:scheme]
  sparkle_dmg_path = options[:sparkle_dmg_path]
  sparkle_upload_user = options[:sparkle_upload_user]
  sparkle_upload_url = options[:sparkle_upload_url]
  sparkle_version = options[:sparkle_version]
  sparkle_signing_team = options[:sparkle_signing_team]
  sparkle_xml_name = options[:sparkle_xml_name]

  dmg_path = smf_path_to_dmg(build_variant)
  update_dir = "#{smf_workspace_dir}/build/"

  release_notes = smf_read_changelog(html: true)
  release_notes_name = "#{scheme}.html"
  File.write("#{update_dir}#{release_notes_name}", release_notes)

  if !File.exists?(dmg_path)
    raise("DMG file #{dmg_path} does not exit. Nothing to upload.")
  end

  app_name = "#{sparkle_dmg_path}#{scheme}.dmg"

  sh("scp -i #{ENV['CUSTOM_SPARKLE_PRIVATE_SSH_KEY']} #{update_dir}#{release_notes_name} '#{sparkle_upload_user}'@#{sparkle_upload_url}:/#{sparkle_dmg_path}#{release_notes_name}")
  sh("scp -i #{ENV['CUSTOM_SPARKLE_PRIVATE_SSH_KEY']} #{dmg_path} '#{sparkle_upload_user}'@#{sparkle_upload_url}:/#{app_name}")

  # Create appcast
  sparkle_private_key = ENV['CUSTOM_SPARKLE_SIGNING_KEY']

  sh "#{@fastlane_commons_dir_path}/commons/ios/smf_upload_with_sparkle/sparkle.sh #{ENV['LOGIN']} #{sparkle_private_key} #{update_dir} #{sparkle_version} #{sparkle_signing_team}"

  appcast_xml = "#{update_dir}#{sparkle_xml_name}"
  appcast_upload_name = sparkle_xml_name
  sh("scp -i #{ENV['CUSTOM_SPARKLE_PRIVATE_SSH_KEY']} #{appcast_xml} '#{sparkle_upload_user}'@#{sparkle_upload_url}:/#{sparkle_dmg_path}#{appcast_upload_name}")
end