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
    
    firebase_app_distribution(
      app: app_id,
      release_notes: smf_read_changelog,
      service_credentials_file: service_credentials_file,
      groups: destinations,
      ipa_path: app_path,
      dsym_path: dsym_path
    )
  end
  