private_lane :smf_build_android_app do |options|

  build_variant = !options[:build_variant].nil? ? options[:build_variant] : ''
  keystore_folder = options[:keystore_folder]

  letters = build_variant.split('')
  letters[0] = letters[0].upcase if letters.length >= 1
  build_variant = letters.join('')

  task = ["assemble#{build_variant}"]

  unless keystore_folder.nil?
    keystore_values = smf_pull_keystore(folder: keystore_folder)

    if keystore_values[:keystore_file]

      task += "bundle#{build_variant}"
      properties = {
        "android.injected.signing.store.file" => keystore_values[:keystore_file],
        "android.injected.signing.store.password" => keystore_values[:keystore_password],
        "android.injected.signing.key.alias" => keystore_values[:keystore_key_alias],
        "android.injected.signing.key.password" => keystore_values[:keystore_key_password]
      }

    end
  end

  gradle(
    tasks: task,
    properties: properties
  )
end
