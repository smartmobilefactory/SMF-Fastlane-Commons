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

  release_notes = smf_read_changelog(html: true)
  release_notes_name = "#{scheme}.html"
  File.write("#{update_dir}#{release_notes_name}", release_notes)

  if !File.exists?(dmg_path)
    raise("DMG file #{dmg_path} does not exit. Nothing to upload.")
  end

  app_name = "#{sparkle_dmg_path}#{scheme}.dmg"

  # Create appcast
  UI.message("Using '#{sparkle_private_key}' as private sparkle 🔑")
  sparkle_private_key = ENV[sparkle_private_key]

  sh "#{@fastlane_commons_dir_path}/commons/ios/smf_upload_with_sparkle/sparkle.sh #{ENV['LOGIN']} #{sparkle_private_key} #{update_dir} #{sparkle_version} #{sparkle_signing_team}"

  if use_custom_info_plist_path == true
    sh("hdiutil attach #{source_dmg_path}")
    app_name = File.basename(source_dmg_path).sub('.dmg', '')
    info_plist_path = "/Volumes/#{app_name}/#{app_name}.app/Contents/Info.plist".shellescape
    xml_path = File.join(target_directory, sparkle_xml_name)
    _smf_prepare_sparkle_xml_for_upload(release_notes_name, info_plist_path, xml_path)
    sh("hdiutil detach /Volumes/#{app_name}")
  else
    sparkle_xml_path = "#{smf_workspace_dir}/build/#{sparkle_xml_name}"
    info_plist_path = File.join(smf_path_to_ipa_or_app(build_variant), '/Contents/Info.plist').shellescape
    _smf_prepare_sparkle_xml_for_upload(release_notes_name, info_plist_path, sparkle_xml_path)
  end

  unless sparkle_upload_url.nil? || sparkle_upload_user.nil?

    appcast_xml = "#{update_dir}#{sparkle_xml_name}"
    appcast_upload_name = sparkle_xml_name
    if create_intermediate_folder == true
      # We put the package elements in a folder, and upload the folder
      # We are copying instead of moving because other lanes might depend on the original path
      intermediate_directory_path = _smf_create_intermediate_directory(update_dir, info_plist_path)
      sh("cp #{dmg_path.shellescape} #{intermediate_directory_path}")
      sh("cp #{appcast_xml.shellescape} #{intermediate_directory_path}")
      sh("cp #{update_dir.shellescape}#{release_notes_name} #{intermediate_directory_path}")
      sh("scp -i #{ENV['CUSTOM_SPARKLE_PRIVATE_SSH_KEY']} -r #{intermediate_directory_path} '#{sparkle_upload_user}'@#{sparkle_upload_url}:/#{sparkle_dmg_path.shellescape}")
    else
      # We upload the three elements directly
    sh("scp -i #{ENV['CUSTOM_SPARKLE_PRIVATE_SSH_KEY']} #{update_dir.shellescape}#{release_notes_name} '#{sparkle_upload_user}'@#{sparkle_upload_url}:/#{sparkle_dmg_path.shellescape}#{release_notes_name}")
    sh("scp -i #{ENV['CUSTOM_SPARKLE_PRIVATE_SSH_KEY']} #{dmg_path.shellescape} '#{sparkle_upload_user}'@#{sparkle_upload_url}:/#{app_name.shellescape}")
    sh("scp -i #{ENV['CUSTOM_SPARKLE_PRIVATE_SSH_KEY']} #{appcast_xml.shellescape} '#{sparkle_upload_user}'@#{sparkle_upload_url}:/#{sparkle_dmg_path.shellescape}#{appcast_upload_name}")
    end
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
