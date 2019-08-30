private_lane :smf_build_android_app do |options|

  build_variant = options[:build_variant]

  if !build_variant
    UI.important("Building all variants")
    build_variant = ""
  else
    UI.important("Building variant " + build_variant)
  end

  addition = ""
  if ENV[$SMF_KEYSTORE_FILE_KEY]
    KEYSTORE_FILE = ENV[$SMF_KEYSTORE_FILE_KEY]
    KEYSTORE_PASSWORD = ENV[$SMF_KEYSTORE_PASSWORD_KEY]
    KEYSTORE_KEY_ALIAS = ENV[$SMF_KEYSTORE_KEY_ALIAS_KEY]
    KEYSTORE_KEY_PASSWORD = ENV[$SMF_KEYSTORE_KEY_PASSWORD_KEY]
    addition = " -Pandroid.injected.signing.store.file='#{KEYSTORE_FILE}'"
    addition << " -Pandroid.injected.signing.store.password='#{KEYSTORE_PASSWORD}'"
    addition << " -Pandroid.injected.signing.key.alias='#{KEYSTORE_KEY_ALIAS}'"
    addition << " -Pandroid.injected.signing.key.password='#{KEYSTORE_KEY_PASSWORD}'"
  end

  gradle(task: "assemble" + build_variant + addition)
end
