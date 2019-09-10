private_lane :smf_build_android_app do |options|

  build_variant = !options[:build_variant].nil? ? options[:build_variant] : ''
  keystore_folder = options[:keystore_folder]

  addition = ''

  unless keystore_folder.nil?
    keystore_values = smf_pull_keystore(folder: keystore_folder)

    if keystore_values[:keystore_file]
      addition = " -Pandroid.injected.signing.store.file='#{keystore_values[:keystore_file]}'"
      addition << " -Pandroid.injected.signing.store.password='#{keystore_values[:keystore_password]}'"
      addition << " -Pandroid.injected.signing.key.alias='#{keystore_values[:keystore_key_alias]}'"
      addition << " -Pandroid.injected.signing.key.password='#{keystore_values[:keystore_key_password]}'"
    end
  end

  letters = build_variant.split('')
  letters[0] = letters[0].upcase if letters.length >= 1
  build_variant = letters.join('')

  gradle(task: 'assemble' + build_variant + addition)
end
