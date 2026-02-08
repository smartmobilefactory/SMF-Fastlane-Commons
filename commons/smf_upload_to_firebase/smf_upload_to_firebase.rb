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
  # Try AI-generated release notes if enabled
  if smf_ai_release_notes_enabled?
    UI.message("AI release notes enabled, attempting generation...")

    # Read ticket tags from changelog
    ticket_tags_string = smf_read_changelog(type: :ticket_tags)
    ticket_tags = ticket_tags_string.is_a?(Array) ? ticket_tags_string : ticket_tags_string.to_s.split(' ')

    if ticket_tags.any?
      # Generate tickets data from tags
      tickets = smf_generate_tickets_from_tags(ticket_tags)

      # Generate AI release notes
      ai_notes = smf_generate_ai_release_notes(tickets, {
        build_variant: build_variant,
        language: 'en',
        max_length: 500
      })

      if ai_notes && !ai_notes.empty?
        UI.success("Using AI-generated release notes")
        return ai_notes
      else
        UI.important("AI generation failed, falling back to standard changelog")
      end
    else
      UI.message("No ticket tags found, using standard changelog")
    end
  end

  # Fallback to standard changelog
  UI.message("Using standard changelog for release notes")
  smf_read_changelog
end

