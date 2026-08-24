private_lane :smf_upload_to_testflight do |options|

  slack_channel = options[:slack_channel]

  if options[:upload_itc] != true
    UI.message("Upload to TestFlight is not enabled for this build variant.")
    next
  end

  required_xcode_version = options[:required_xcode_version]
  itc_team_id = options[:itc_team_id]
  username = !options[:apple_id].nil? ? options[:apple_id] : 'development@smfhq.com'
  itc_apple_id = options[:itc_apple_id]
  skip_waiting_for_build_processing = options[:skip_waiting_for_build_processing] == true
  itc_platform = options[:itc_platform]

  # TestFlight changelog / "What to Test" (CBENEFIOS-1900)
  # Priority: 1. options[:changelog], 2. ENV['TESTFLIGHT_CHANGELOG'], 3. file, 4. default
  changelog = options[:changelog]
  if changelog.nil? && ENV['TESTFLIGHT_CHANGELOG']
    changelog = ENV['TESTFLIGHT_CHANGELOG']
    UI.message("📝 Using changelog from TESTFLIGHT_CHANGELOG environment variable")
  end
  if changelog.nil?
    changelog_file = "fastlane/testflight_changelog.txt"
    if File.exist?(changelog_file)
      changelog = File.read(changelog_file).strip
      UI.message("📝 Using changelog from #{changelog_file}")
    end
  end
  if changelog
    UI.message("📋 TestFlight changelog: #{changelog[0..100]}#{changelog.length > 100 ? '...' : ''}")
  end

  # Create App Store Connect API key if environment variables are available
  api_key = nil
  if ENV['APP_STORE_CONNECT_API_KEY_ID'] && ENV['APP_STORE_CONNECT_API_KEY_ISSUER_ID'] && ENV['APP_STORE_CONNECT_API_KEY_PATH']
    UI.message('Using App Store Connect API key for authentication')
    api_key = app_store_connect_api_key(
      key_id: ENV['APP_STORE_CONNECT_API_KEY_ID'],
      issuer_id: ENV['APP_STORE_CONNECT_API_KEY_ISSUER_ID'],
      key_filepath: ENV['APP_STORE_CONNECT_API_KEY_PATH'],
      duration: 1200
    )
  else
    UI.message('Using username/password authentication (fallback)')
  end

  ENV["FASTLANE_ITC_TEAM_ID"] = itc_team_id

  smf_setup_correct_xcode_executable_for_build(required_xcode_version: required_xcode_version)

  _smf_itunes_precheck(
      options[:build_variant],
      slack_channel,
      options[:bundle_identifier],
      username,
      options[:precheck_include_in_app_purchases]
  )

  UI.important("Uploading the build to TestFlight.")

  upload_params = {
    apple_id: itc_apple_id,
    team_id: itc_team_id,
    api_key: api_key,
    username: api_key ? nil : username,
    skip_waiting_for_build_processing: skip_waiting_for_build_processing,
    ipa: smf_path_to_ipa_or_app.gsub('.zip', ''),
    app_platform: itc_platform
  }

  # Add changelog if available (CBENEFIOS-1900)
  if changelog && !changelog.empty?
    upload_params[:changelog] = changelog
    UI.message("✅ Including 'What to Test' notes in TestFlight upload")
  end

  # Hand the build to the beta groups the project names, instead of someone
  # opening App Store Connect after every upload and doing it by hand.
  #
  # Internal groups are reached the same way as external ones — App Store Connect
  # keeps both under betaGroups and pilot matches on the name — so this needs no
  # separate setting for the two kinds.
  #
  # The two flags are read from the project rather than decided here. pilot
  # defaults submit_beta_review to true and submits whenever groups are given:
  #
  #   if options[:submit_beta_review] && (options[:groups] || options[:distribute_external])
  #
  # so naming a group would otherwise also send the build to Apple's beta review.
  # Both default to false because that is the answer that cannot surprise anyone:
  # a project wanting external distribution or a review submission says so, and a
  # project that only wants its testers to get the build says nothing.
  testflight_groups = options[:testflight_groups]
  if testflight_groups && !testflight_groups.empty?
    distribute_external = options[:testflight_distribute_external] == true
    submit_beta_review = options[:testflight_submit_beta_review] == true

    upload_params[:groups] = testflight_groups
    upload_params[:distribute_external] = distribute_external
    upload_params[:submit_beta_review] = submit_beta_review

    # Named in full because a mismatch is silent: pilot looks the groups up by
    # name and, finding none, simply assigns nothing. Printing what was asked for
    # is what lets a typo be seen in the log rather than as a build that quietly
    # reaches no tester.
    UI.message("👥 Assigning the build to TestFlight group(s): #{testflight_groups.join(', ')}")
    UI.message("   distribute_external: #{distribute_external} · submit_beta_review: #{submit_beta_review}")
  end

  upload_to_testflight(upload_params)
end

def _smf_itunes_precheck(build_variant, slack_channel, bundle_identifier, username, include_in_app_purchases = true)

  begin

    # Create API key for precheck if available
    api_key_for_precheck = nil
    if ENV['APP_STORE_CONNECT_API_KEY_ID'] && ENV['APP_STORE_CONNECT_API_KEY_ISSUER_ID'] && ENV['APP_STORE_CONNECT_API_KEY_PATH']
      api_key_for_precheck = app_store_connect_api_key(
        key_id: ENV['APP_STORE_CONNECT_API_KEY_ID'],
        issuer_id: ENV['APP_STORE_CONNECT_API_KEY_ISSUER_ID'],
        key_filepath: ENV['APP_STORE_CONNECT_API_KEY_PATH'],
        duration: 1200
      )
    end

    precheck(
        api_key: api_key_for_precheck,
        username: api_key_for_precheck ? nil : username,
        app_identifier: bundle_identifier,
        include_in_app_purchases: include_in_app_purchases
    )

  rescue => exception

    title = "Fastlane Precheck found Metadata issues in App Store Connect for #{smf_get_default_name_and_version(build_variant)} 😢"
    message = "The build will continue to upload to App Store Connect, but you may need to fix the Metadata issues before releasing the app."

    smf_send_message(
        title: title,
        message: message,
        type: "warning",
        exception: exception,
        slack_channel: slack_channel
    )
  end
end