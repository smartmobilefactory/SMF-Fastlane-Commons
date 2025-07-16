private_lane :smf_build_android_app do |options|

  build_variant = !options[:build_variant].nil? ? options[:build_variant] : ''
  keystore_folder = options[:keystore_folder]

  letters = build_variant.split('')
  letters[0] = letters[0].upcase if letters.length >= 1
  build_variant_capitalized = letters.join('')

  # Check if use_aab flag is set for this build variant
  use_aab = smf_config_get(build_variant, :use_aab) || false

  # Determine which tasks to run based on use_aab flag
  if use_aab
    # AAB-only mode: only build AAB
    tasks = ["bundle#{build_variant_capitalized}"]
    UI.message("AAB-only build mode (use_aab=true) - building bundle only")
  else
    # Legacy mode: build both APK and AAB
    tasks = ["assemble#{build_variant_capitalized}"]
    UI.message("Legacy build mode (use_aab=false or not set) - building APK and AAB")
  end

  unless keystore_folder.nil?
    keystore_values = smf_pull_keystore(folder: keystore_folder)

    if keystore_values[:keystore_file]

      # In legacy mode, also build AAB if we have keystore
      if !use_aab
        tasks.push("bundle#{build_variant_capitalized}")
      end
      
      properties = {
        "android.injected.signing.store.file" => keystore_values[:keystore_file],
        "android.injected.signing.store.password" => keystore_values[:keystore_password],
        "android.injected.signing.key.alias" => keystore_values[:keystore_key_alias],
        "android.injected.signing.key.password" => keystore_values[:keystore_key_password]
      }

    end
  end

  gradle(
    tasks: tasks,
    properties: properties
  )
end
