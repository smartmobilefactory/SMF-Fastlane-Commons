private_lane :smf_build_android_app do |options|

  build_variant = options[:build_variant]
  keystore_folder = options[:keystore_folder]

  if !build_variant
    UI.important("Building all variants")
    build_variant = ""
  else
    UI.important("Building variant " + build_variant)
  end

  addition = smf_pull_keystore(folder: keystore_folder)

  gradle(task: "assemble" + build_variant + addition)
end
