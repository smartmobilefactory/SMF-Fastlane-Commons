private_lane :smf_build_android_app do |options|

  build_variant = !options[:build_variant].nil? ? options[:build_variant] : ''
  keystore_folder = options[:keystore_folder]

  unless keystore_folder.nil?
    keystore_values = smf_pull_keystore(folder: keystore_folder)

    if keystore_values[:keystore_file]
      properties = {
        "android.injected.signing.store.file" => keystore_values[:keystore_file],
        "android.injected.signing.store.password" => keystore_values[:keystore_password],
        "android.injected.signing.key.alias" => keystore_values[:keystore_key_alias],
        "android.injected.signing.key.password" => keystore_values[:keystore_key_password]
      }

    end
  end

  gradle(
    tasks: ['assemble', 'bundle'],
    flavor: build_variant,
    properties: properties
  )

  UI.message("AAB PATH: #{ENV['GRADLE_AAB_OUTPUT_PATH']}")
  UI.message("APK PATH: #{ENV['GRADLE_APK_OUTPUT_PATH']}")
end
