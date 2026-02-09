private_lane :smf_ios_upload_to_firebase do |options|

    build_variant = options[:build_variant]
    app_id = options[:app_id]
    destinations = options[:destinations]
    escaped_filename = options[:escaped_filename]
    path_to_ipa_or_app = options[:path_to_ipa_or_app]

    if app_id.nil? || app_id.empty?
      UI.message("Skipping upload to Firebase as the Firebase App ID is missing.")
      return
    end

    service_credentials_file = ENV['FIREBASE_CREDENTIALS']

    if service_credentials_file.nil?
      UI.message("Skipping upload to Firebase as Firebase credentials are missing.")
      return
    end

    dsym_path = "#{smf_workspace_dir}/build/#{escaped_filename}.app.dSYM.zip"
    UI.message("Constructed the dsym path \"#{dsym_path}\"")
    unless File.exist?(dsym_path)
      dsym_path = nil
      UI.message('Using nil as dsym_path as no file exists at the constructed path.')
    end

    app_path = path_to_ipa_or_app

    unless File.exist?(app_path)
        app_path = nil
        UI.message("Binary file #{app_path} does not exist. Nothing to upload.")
        raise("Binary file #{app_path} does not exist. Nothing to upload.")
    end

    UI.message("Uploading iOS app to Firebase App Distribution: #{app_path}")

    # Try AI-generated release notes, fallback to standard changelog
    release_notes = _smf_get_release_notes_for_firebase(build_variant)

    firebase_app_distribution(
      app: app_id,
      release_notes: release_notes,
      service_credentials_file: service_credentials_file,
      groups: destinations,
      ipa_path: app_path
    )
  end
  
  private_lane :smf_android_upload_to_firebase do |options|

    android_artifact_path = options[:android_artifact_path]
    android_artifact_type = options[:android_artifact_type]

    app_id = options[:app_id]
    destinations = options[:destinations]
    build_variant = options[:build_variant]

    UI.message("Binary type #{android_artifact_type}")
    UI.message("Path for binary: #{android_artifact_path}")

    if app_id.nil? || app_id.empty?
      UI.message("Skipping upload to Firebase as the Firebase App ID is missing.")
      return
    end

    service_credentials_file = ENV['FIREBASE_CREDENTIALS']

    if service_credentials_file.nil?
      UI.message("Skipping upload to Firebase as Firebase credentials are missing.")
      return
    end

    if android_artifact_path.nil? || !File.exist?(android_artifact_path)
      UI.message("No valid APK or AAB file found to upload.")
      raise("Binary file #{android_artifact_path} does not exist. Nothing to upload.")
    end

    UI.message("Uploading Android #{android_artifact_type} to Firebase App Distribution: #{android_artifact_path}")

    # Try AI-generated release notes, fallback to standard changelog
    release_notes = _smf_get_release_notes_for_firebase(build_variant)

    # Upload the AAB or APK to Firebase App Distribution
    firebase_app_distribution(
      app: app_id,
      release_notes: release_notes,
      service_credentials_file: service_credentials_file,
      groups: destinations,
      android_artifact_path: android_artifact_path, # Path to APK or AAB
      android_artifact_type: android_artifact_type # Specify whether it's an APK or AAB
    )
  end

# Helper function to get release notes for Firebase
# Tries AI-generated notes first, falls back to standard changelog
# @param build_variant [String] Build variant (e.g., 'germany_alpha', 'austria_beta')
# @return [String] Release notes for Firebase
def _smf_get_release_notes_for_firebase(build_variant)
  UI.header("🤖 AI Release Notes Generation")
  UI.message("Build variant: #{build_variant}")

  # Try AI-generated release notes if enabled
  if smf_ai_release_notes_enabled?
    config = smf_get_ai_release_notes_config
    UI.message("✅ AI release notes ENABLED")
    UI.message("   Provider: #{config[:provider]}")
    UI.message("   Model: #{config[:model]}")
    UI.message("   API Key Env: #{config[:api_key_env]}")
    UI.message("   Alpha Mode: #{config[:alpha_mode]}")
    UI.message("   Beta Mode: #{config[:beta_mode]}")

    # Read the standard changelog as array (contains commit messages)
    changelog_text = smf_read_changelog.to_s
    changelog_array = changelog_text.split("\n").map(&:strip).reject(&:empty?)
    UI.message("📝 Changelog entries: #{changelog_array.length}")

    # Get ticket tags WITH their commit messages (from the central utility)
    ticket_data = smf_get_ticket_tags_with_commits_from_changelog(changelog_array)
    ticket_tags = ticket_data[:tags]
    ticket_commits = ticket_data[:commits_by_tag]

    UI.message("🎫 Ticket tags found: #{ticket_tags.length}")
    ticket_tags.each do |tag|
      commits = ticket_commits[tag] || []
      UI.message("   #{tag}: #{commits.length} commit(s)")
      commits.each { |c| UI.message("      - #{c[0..80]}#{'...' if c.length > 80}") }
    end

    if ticket_tags.any?
      # Generate tickets data from tags (fetches Jira titles, links, etc.)
      UI.message("🔍 Fetching Jira ticket details...")
      tickets = smf_generate_tickets_from_tags(ticket_tags)
      UI.message("   Normal tickets: #{tickets[:normal]&.length || 0}")
      UI.message("   Linked tickets: #{tickets[:linked]&.length || 0}")
      UI.message("   Unknown tickets: #{tickets[:unknown]&.length || 0}")

      tickets[:normal]&.each do |t|
        UI.message("   📋 #{t[:tag]}: #{t[:title]}")
      end

      # Generate AI release notes
      UI.message("🚀 Calling AI API...")
      ai_notes = smf_generate_ai_release_notes(tickets, {
        build_variant: build_variant,
        language: 'en',
        max_length: 500,
        ticket_commits: ticket_commits
      })

      if ai_notes && !ai_notes.empty?
        UI.success("✅ AI release notes generated successfully!")
        UI.message("📄 Generated notes (#{ai_notes.length} chars):")
        UI.message("─" * 60)
        UI.message(ai_notes)
        UI.message("─" * 60)
        return ai_notes
      else
        UI.important("⚠️ AI generation failed, falling back to standard changelog")
      end
    else
      UI.message("ℹ️ No ticket tags found, using standard changelog")
    end
  else
    UI.message("❌ AI release notes DISABLED")
    UI.message("   Check Config.json 'ai_release_notes.enabled' and API key environment variable")
  end

  # Fallback to standard changelog
  UI.message("📝 Using standard changelog for release notes")
  smf_read_changelog
end

