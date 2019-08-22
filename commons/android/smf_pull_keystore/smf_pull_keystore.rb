
private_lane :smf_pull_keystore do |options|

  clone_root_folder = options[:clone_root_folder]
  clone_root_folder = @fastlane_commons_dir_path if !clone_root_folder

  keystoreFolder = options[:folder]

  Dir.chdir(clone_root_folder) do
    sh("rm -r -f ./Android-Keystores")
    sh("git clone https://github.com/smartmobilefactory/Android-Keystores.git")
    sh("cd ./Android-Keystores; sh crypto.sh -decrypt #{keystoreFolder}")
  end

  properties = load_properties("#{clone_root_folder}/Android-Keystores/keystores/#{keystoreFolder}/keystore.properties")
  ENV[$SMF_KEYSTORE_FILE_KEY] = File.absolute_path("#{clone_root_folder}/Android-Keystores/keystores/#{keystoreFolder}/keystore.jks")
  ENV[$SMF_KEYSTORE_PASSWORD_KEY] = properties[$SMF_KEYSTORE_PASSWORD_KEY]
  ENV[$SMF_KEYSTORE_KEY_ALIAS_KEY] = properties[$SMF_KEYSTORE_KEY_ALIAS_KEY]
  ENV[$SMF_KEYSTORE_KEY_PASSWORD_KEY] = properties[$SMF_KEYSTORE_KEY_PASSWORD_KEY]
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