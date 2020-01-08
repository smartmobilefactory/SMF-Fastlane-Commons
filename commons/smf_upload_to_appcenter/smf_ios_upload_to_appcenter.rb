private_lane :smf_ios_upload_to_appcenter do |options|

  build_variant = options[:build_variant]
  build_number = options[:build_number]
  app_id = options[:app_id]
  escaped_filename = options[:escaped_filename]
  path_to_ipa_or_app = options[:path_to_ipa_or_app]
  is_mac_app = !options[:is_mac_app].nil? ? options[:is_mac_app] : false
  destinations = options[:destinations].nil? ? 'Collaborators' : options[:destinations]
  sparkle_xml_name = options[:sparkle_xml_name]
  upload_to_appcenter = options[:upload_to_appcenter]

  app_name, owner_name, owner_id = get_app_details(app_id)

  dsym_path = Pathname.getwd.dirname.to_s + "/build/#{escaped_filename}.app.dSYM.zip"
  UI.message("Constructed the dsym path \"#{dsym_path}\"")
  unless File.exist?(dsym_path)
    dsym_path = nil
    UI.message('Using nil as dsym_path as no file exists at the constructed path.')
  end

  NO_APP_FAILURE = 'NO_APP_FAILURE'

  app_path = path_to_ipa_or_app

  if is_mac_app
    version_number = smf_get_version_number(build_variant)

    info_plist_path = File.join(app_path, '/Contents/Info.plist')

    app_path = app_path.sub('.app', '.dmg')

    raise("Binary file #{app_path} does not exit. Nothing to upload.") unless File.exist?(app_path)

    begin

      su_feed_url = sh("defaults read #{info_plist_path} SUFeedURL").gsub("\n", '')

      UI.message("su_feed_url: #{su_feed_url.to_s}")

      doc = File.open(sparkle_xml_name) { |f| Nokogiri::XML(f) }
      UI.message(doc.to_s)
      description = doc.at_css('rss channel item description')
      description.add_next_sibling("<sparkle:releaseNotesLink>#{su_feed_url}</sparkle:releaseNotesLink>")
      description.remove
      doc.xpath('//text()').find_all { |t| t.to_s.strip == '' }.map(&:remove)
      UI.message(doc.to_s)

      File.open(sparkle_xml_name, 'w+') do |f|
        f.write(doc)
      end
    rescue => exception
      UI.important('An error occurred during changing item description to sparkle:releaseNotesLink. Will continue.')
    end

    if upload_to_appcenter
      package_path = app_path.sub_ext('.zip')
      sh "cd \"#{File.dirname(app_path)}\"; zip -r -q \"#{package_path}\" \"./#{escaped_filename}.dmg\" \"./#{escaped_filename}.html\" \"./#{sparkle_xml_name}\""
      app_path = package_path
    end

    UI.message('Upload mac app to AppCenter.')
    appcenter_upload(
        api_token: ENV[$SMF_APPCENTER_API_TOKEN_ENV_KEY],
        owner_name: owner_name,
        app_name: app_name,
        build_number: build_number,
        version: version_number,
        file: app_path,
        dsym: dsym_path,
        notify_testers: true,
        destinations: destinations,
        release_notes: smf_read_changelog
    )
  else

    raise("Binary file #{app_path} does not exit. Nothing to upload.") unless File.exist?(app_path)

    UI.message('Upload iOS app to AppCenter.')
    appcenter_upload(
        api_token: ENV[$SMF_APPCENTER_API_TOKEN_ENV_KEY],
        owner_name: owner_name,
        app_name: app_name,
        file: app_path,
        dsym: dsym_path,
        notify_testers: true,
        destinations: destinations,
        release_notes: smf_read_changelog
    )
  end

#smf_create_appcenter_push(
#  app_owner: owner_id,
#  app_display_name: app_name,
#  app_id: app_id
#)
end
