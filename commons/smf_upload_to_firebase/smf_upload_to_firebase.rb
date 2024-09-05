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
      ipa_path: app_path
    )
  end
  
  private_lane :smf_android_upload_to_firebase do |options|

    android_artifact_path = options[:aab_path] || options[:apk_path] # Prioritize AAB, fallback to APK
    android_artifact_type = options[:aab_path] ? "AAB" : "APK"
    app_id = options[:app_id]
    destinations = options[:destinations]
    
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
  
    # Upload the AAB or APK to Firebase App Distribution
    firebase_app_distribution(
      app: app_id,
      release_notes: smf_read_changelog, # You can customize this with your changelog method
      service_credentials_file: service_credentials_file,
      groups: destinations,
      android_artifact_path: android_artifact_path, # Path to APK or AAB
      android_artifact_type: android_artifact_type # Specify whether it's an APK or AAB
    )
  end
  
  