
private_lane :smf_pull_keystore do |options|

  clone_root_folder = options[:clone_root_folder]
  clone_root_folder = @fastlane_commons_dir_path if !clone_root_folder

  keystoreFolder = options[:folder]

  if keystoreFolder.nil?
    return ""
  end

  Dir.chdir(clone_root_folder) do
    sh("rm -r -f ./Android-Keystores")
    sh("git clone https://github.com/smartmobilefactory/Android-Keystores.git")
    sh("cd ./Android-Keystores; sh crypto.sh -decrypt #{keystoreFolder}")
  end

  properties = load_properties("#{clone_root_folder}/Android-Keystores/keystores/#{keystoreFolder}/keystore.properties")
  keystore_file = File.absolute_path("#{clone_root_folder}/Android-Keystores/keystores/#{keystoreFolder}/keystore.jks")
  keystore_password = properties[$SMF_KEYSTORE_PASSWORD_KEY]
  keystore_key_alias  = properties[$SMF_KEYSTORE_KEY_ALIAS_KEY]
  keystore_key_password = properties[$SMF_KEYSTORE_KEY_PASSWORD_KEY]

  addition = ""
  if keystore_file
    addition = " -Pandroid.injected.signing.store.file='#{keystore_file}'"
    addition << " -Pandroid.injected.signing.store.password='#{keystore_password}'"
    addition << " -Pandroid.injected.signing.key.alias='#{keystore_key_alias}'"
    addition << " -Pandroid.injected.signing.key.password='#{keystore_key_password}'"
  end

  addition
end

def load_properties(properties_filename)
  properties = {}
  File.open(properties_filename, 'r') do |properties_file|
    properties_file.read.each_line do |line|
      line.strip!
      if (line[0] != ?# and line[0] != ?=)
        i = line.index('=')
        if (i)
          properties[line[0..i - 1].strip] = line[i + 1..-1].strip
        else
          properties[line] = ''
        end
      end
    end
  end
  properties
end