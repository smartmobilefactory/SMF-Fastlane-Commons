private_lane :smf_build_android_app do |options|

  build_variant = options[:build_variant]
  keystore_folder = options[:keystore_folder]

  if !build_variant
    UI.important("Building all variants")
    build_variant = ""
  else
    UI.important("Building variant " + build_variant.to_s)
  end

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

  gradle(task: "assemble" + build_variant.to_s + addition)
end
