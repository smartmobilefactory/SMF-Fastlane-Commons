private_lane :smf_upload_with_sparkle do |options|

  if @platform != :macos
    UI.error("Sparkle is only available for macOS, your are on: #{@platform.to_s}")
    raise "Error using Sparkle on none macOS platform"
  end

  build_variant = options[:build_variant]
  scheme = options[:scheme]
  create_intermediate_folder = options[:create_intermediate_folder].nil? ? false : options[:create_intermediate_folder]
  sparkle_dmg_path = options[:sparkle_dmg_path]
  sparkle_upload_user = options[:sparkle_upload_user]
  sparkle_upload_url = options[:sparkle_upload_url]
  sparkle_version = options[:sparkle_version]
  sparkle_signing_team = options[:sparkle_signing_team]
  sparkle_xml_name = options[:sparkle_xml_name]
  sparkle_private_key = options[:sparkle_private_key]

  # If the DMG's Info.plist contains a valid URL for key SMFSUAlternativeFeedURL, we will create a second Sparkle package in a sub-folder named `alternative_channel_directory_name`
  # Changing this value here will have some impacts on alternative channel URLs for mac apps. See https://sosimple.atlassian.net/browse/STRMAC-2306
  alternative_channel_directory_name = 'test'

  # Optional
  source_dmg_path = options[:source_dmg_path]
  target_directory = options[:target_directory]

  use_custom_info_plist_path = !source_dmg_path.nil?

  if sparkle_private_key.nil? || ENV[sparkle_private_key].nil?
    UI.error('Sparkle private key is either not set in the Config.json, or there is no credential stored in Jenkins')
    raise 'Error none existing private key credential'
  end

  dmg_path = source_dmg_path.nil? ? smf_path_to_dmg(build_variant) : source_dmg_path
  update_dir = target_directory.nil? ? "#{smf_workspace_dir}/build/" : target_directory

  release_notes = smf_read_changelog(type: :html)
  release_notes_name = "#{scheme}.html"
  release_notes_path = "#{update_dir}#{release_notes_name}"
  File.write(release_notes_path, release_notes)

  if !File.exist?(dmg_path)
    raise("DMG file #{dmg_path} does not exit. Nothing to upload.")
  end

  app_name = File.basename(dmg_path).sub('.dmg', '')

  # Create appcast
  UI.message("Using '#{sparkle_private_key}' as private sparkle 🔑")
  sparkle_private_key = ENV[sparkle_private_key]

  sh "#{@fastlane_commons_dir_path}/commons/ios/smf_upload_with_sparkle/sparkle.sh #{ENV[$KEYCHAIN_LOGIN_ENV_KEY]} #{sparkle_private_key} #{update_dir} #{sparkle_version} #{sparkle_signing_team}"

  if use_custom_info_plist_path == true
    info_plist_path = "/Volumes/#{app_name}/#{app_name}.app/Contents/Info.plist".shellescape
    xml_path = File.join(target_directory, sparkle_xml_name)
    _smf_prepare_sparkle_xml_for_upload(release_notes_name, info_plist_path, xml_path)
  else
    xml_path = "#{smf_workspace_dir}/build/#{sparkle_xml_name}"
    info_plist_path = File.join(smf_path_to_ipa_or_app, '/Contents/Info.plist').shellescape
    _smf_prepare_sparkle_xml_for_upload(release_notes_name, info_plist_path, xml_path)
  end

  alternative_channel_directory_path = _smf_prepare_alternative_channel_directory(update_dir, info_plist_path, xml_path, dmg_path, release_notes_path, alternative_channel_directory_name)

  unless sparkle_upload_url.nil? || sparkle_upload_user.nil?

    appcast_xml = "#{update_dir}#{sparkle_xml_name}"
    appcast_upload_name = sparkle_xml_name
    if create_intermediate_folder == true
      # We put the package elements in a folder, and upload the folder
      # We are copying instead of moving because other lanes might depend on the original path
      intermediate_directory_path = _smf_create_intermediate_directory(update_dir, info_plist_path)
      sh("cp #{dmg_path.shellescape} #{intermediate_directory_path.shellescape}")
      sh("cp #{appcast_xml.shellescape} #{intermediate_directory_path.shellescape}")
      sh("cp #{update_dir.shellescape}#{release_notes_name} #{intermediate_directory_path.shellescape}")
      sh("mv #{alternative_channel_directory_path.shellescape} #{intermediate_directory_path.shellescape}") unless alternative_channel_directory_path.nil?
      sh("scp -i #{ENV['CUSTOM_SPARKLE_PRIVATE_SSH_KEY']} -r #{intermediate_directory_path.shellescape} '#{sparkle_upload_user}'@#{sparkle_upload_url}:/#{sparkle_dmg_path}")
    else
      # We upload the three elements directly
    sh("scp -i #{ENV['CUSTOM_SPARKLE_PRIVATE_SSH_KEY']} #{update_dir.shellescape}#{release_notes_name} '#{sparkle_upload_user}'@#{sparkle_upload_url}:/#{sparkle_dmg_path}")
    sh("scp -i #{ENV['CUSTOM_SPARKLE_PRIVATE_SSH_KEY']} #{dmg_path.shellescape} '#{sparkle_upload_user}'@#{sparkle_upload_url}:/#{sparkle_dmg_path}")
    sh("scp -i #{ENV['CUSTOM_SPARKLE_PRIVATE_SSH_KEY']} #{appcast_xml.shellescape} '#{sparkle_upload_user}'@#{sparkle_upload_url}:/#{sparkle_dmg_path}")
    sh("scp -i #{ENV['CUSTOM_SPARKLE_PRIVATE_SSH_KEY']} -r #{alternative_channel_directory_path.shellescape} '#{sparkle_upload_user}'@#{sparkle_upload_url}:/#{sparkle_dmg_path}") unless alternative_channel_directory_path.nil?
    end
  end
end


def _smf_prepare_alternative_channel_directory(base_directory, info_plist_path, xml_path, dmg_path, release_notes_path, alternative_channel_directory_name)
  su_rc_channel_url = sh("defaults read #{info_plist_path} SMFSUAlternativeFeedURL").gsub("\n", '')

  if su_rc_channel_url =~ /\A#{URI::regexp}\z/
    begin
      UI.message('Creating alternative package')
     directory_path = "#{base_directory}#{alternative_channel_directory_name}/"
     Dir.mkdir(directory_path)
    
     # Copy all content inside new folder
     sh("cp #{dmg_path.shellescape} #{directory_path}")
     sh("cp #{xml_path.shellescape} #{directory_path}")
     sh("cp #{release_notes_path.shellescape} #{directory_path}")

     # Replace original url with alternative URL in new XML
     su_feed_url = sh("defaults read #{info_plist_path} SUFeedURL").gsub("\n", '')
     xml_name = su_feed_url.split('/').last
    
     # We want to find the URL but without the XML name
     url_to_find = su_feed_url.sub(xml_name, '')
     url_to_replace = su_rc_channel_url.sub(xml_name, '')
     xml_content = File.read(xml_path)
     new_contents = xml_content.gsub(url_to_find, url_to_replace)
     
     if xml_content == new_contents
      raise "Alternative Appcast XML creation failed. Result is identical to source"
     end 

     alternative_xml_path = "#{directory_path}#{xml_path.split('/').last}"

     File.open(alternative_xml_path, 'w+') do |f|
      f.write(new_contents)
     end

     return directory_path
    rescue => exception
      UI.error("Encountered an error while creating alternative package: #{exception.message}.")
      raise 'Cannot create alternative package. Interrupting process...'
    end
  else
    UI.message('Skipping alternative package creation: Did not find a valid feed URL for key SMFSUAlternativeFeedURL')
    return nil
  end
end

def _smf_prepare_sparkle_xml_for_upload(release_notes_name, info_plist_path, sparkle_xml_path)
  UI.message('Prepare sparkle xml file.')
  # Read SUFeedUrl to get URL
  su_feed_url = sh("defaults read #{info_plist_path} SUFeedURL").gsub("\n", '')

  # set releaseNotesLink to URL of the .html file, which contains the release notes
  html_url = su_feed_url.gsub(/[^\/]+$/,release_notes_name)
  doc = File.open(sparkle_xml_path) { |f| Nokogiri::XML(f) }
  description = doc.at_css('rss channel item description')
  releaseNotesLinkNode = "<sparkle:releaseNotesLink>#{html_url}</sparkle:releaseNotesLink>"

  if description.nil?
    # In case the description is not there, we get the title and insert the release link right after it
    # The title will always be present
    item = doc.at_css('rss channel item title')
    item.add_next_sibling(releaseNotesLinkNode)
  else
    # In case the description is there, we replace it by the releaseNoteLink
    description.add_next_sibling(releaseNotesLinkNode)
    description.remove
  end

  doc.xpath('//text()').find_all { |t| t.to_s.strip == '' }.map(&:remove)

  File.open(sparkle_xml_path, 'w+') do |f|
    f.write(doc)
  end
end

def _smf_create_intermediate_directory(base_directory, info_plist_path)
  begin
    UI.message('Prepare Sparkle intermediate directory.')
    app_name = sh("defaults read #{info_plist_path} CFBundleName").gsub("\n", '')
    version_number = sh("defaults read #{info_plist_path} CFBundleShortVersionString").gsub("\n", '')
    build_number = sh("defaults read #{info_plist_path} CFBundleVersion").gsub("\n", '')
    # To prevent any risk of duplicate folders on the server side, we add the current timestamp
    timestamp = Time.now.to_i

    directory_name = app_name + "-" + version_number + "-" + build_number + "-" + timestamp.to_s
    intermediate_directory_path = "#{base_directory}#{directory_name}"
    UI.message("Will create Sparkle intermediate directory at path: #{intermediate_directory_path}.")
    Dir.mkdir(intermediate_directory_path)
    UI.message("Did create Sparkle intermediate directory at path: #{intermediate_directory_path}.")

    intermediate_directory_path
  rescue => exception
    UI.error("Encountered an error while creating sparkle intermediate directory: #{exception.message}.")
    raise "Cannot create Sparkle intermediate directory. Interrupting process..."
  end
end
