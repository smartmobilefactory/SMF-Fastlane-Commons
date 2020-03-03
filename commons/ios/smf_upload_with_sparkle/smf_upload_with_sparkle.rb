private_lane :smf_upload_with_sparkle do |options|

  if @platform != :macos
    UI.error("Sparkle is only available for macOS, your are on: #{@platform.to_s}")
    raise "Error using Sparkle on none macOS platform"
  end

  build_variant = options[:build_variant]
  scheme = options[:scheme]
  sparkle_dmg_path = options[:sparkle_dmg_path]
  sparkle_upload_user = options[:sparkle_upload_user]
  sparkle_upload_url = options[:sparkle_upload_url]
  sparkle_version = options[:sparkle_version]
  sparkle_signing_team = options[:sparkle_signing_team]
  sparkle_xml_name = options[:sparkle_xml_name]
  sparkle_private_key = options[:sparkle_private_key]

  if sparkle_private_key.nil? || ENV[sparkle_private_key].nil?
    UI.error('Sparkle private key is either not set in the Config.json, or there is no credential stored in Jenkins')
    raise 'Error none existing private key credential'
  end

  dmg_path = smf_path_to_dmg(build_variant)
  update_dir = "#{smf_workspace_dir}/build/"

  release_notes = smf_read_changelog(html: true)
  release_notes_name = "#{scheme}.html"
  File.write("#{update_dir}#{release_notes_name}", release_notes)

  if !File.exists?(dmg_path)
    raise("DMG file #{dmg_path} does not exit. Nothing to upload.")
  end

  app_name = "#{sparkle_dmg_path}#{scheme}.dmg"

  unless sparkle_upload_url.nil? || sparkle_upload_user.nil?
    sh("scp -i #{ENV['CUSTOM_SPARKLE_PRIVATE_SSH_KEY']} #{update_dir}#{release_notes_name} '#{sparkle_upload_user}'@#{sparkle_upload_url}:/#{sparkle_dmg_path}#{release_notes_name}")
    sh("scp -i #{ENV['CUSTOM_SPARKLE_PRIVATE_SSH_KEY']} #{dmg_path} '#{sparkle_upload_user}'@#{sparkle_upload_url}:/#{app_name}")
  end
  # Create appcast
  UI.message("Using '#{sparkle_private_key}' as private sparkle 🔑")
  sparkle_private_key = ENV[sparkle_private_key]

  sh "#{@fastlane_commons_dir_path}/commons/ios/smf_upload_with_sparkle/sparkle.sh #{ENV['LOGIN']} #{sparkle_private_key} #{update_dir} #{sparkle_version} #{sparkle_signing_team}"

  _smf_prepare_sparkle_xml_for_upload(build_variant, sparkle_xml_name, release_notes_name)

  unless sparkle_upload_url.nil? || sparkle_upload_user.nil?
    appcast_xml = "#{update_dir}#{sparkle_xml_name}"
    appcast_upload_name = sparkle_xml_name
    sh("scp -i #{ENV['CUSTOM_SPARKLE_PRIVATE_SSH_KEY']} #{appcast_xml} '#{sparkle_upload_user}'@#{sparkle_upload_url}:/#{sparkle_dmg_path}#{appcast_upload_name}")
  end
end

def _smf_prepare_sparkle_xml_for_upload(build_variant, sparkle_xml_name, release_notes_name)
  UI.message('Prepare sparkle xml file for upload.')
  # Read SUFeedUrl to get URL
  info_plist_path = File.join(smf_path_to_ipa_or_app(build_variant), '/Contents/Info.plist')
  su_feed_url = sh("defaults read #{info_plist_path} SUFeedURL").gsub("\n", '')

  # set releaseNotesLink to URL of the .html file, which contains the release notes
  html_url = su_feed_url.gsub(/[^\/]+$/,release_notes_name)

  sparkle_xml_path = "#{smf_workspace_dir}/build/#{sparkle_xml_name}"
  doc = File.open(sparkle_xml_path) { |f| Nokogiri::XML(f) }
  description = doc.at_css('rss channel item description')

  unless description.nil?
    description.add_next_sibling("<sparkle:releaseNotesLink>#{html_url}</sparkle:releaseNotesLink>")
    description.remove
    doc.xpath('//text()').find_all { |t| t.to_s.strip == '' }.map(&:remove)

    File.open(sparkle_xml_path, 'w+') do |f|
      f.write(doc)
    end
  end
end