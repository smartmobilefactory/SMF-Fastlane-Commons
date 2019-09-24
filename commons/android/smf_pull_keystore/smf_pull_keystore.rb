private_lane :smf_pull_keystore do |options|

  clone_root_folder = !options[:clone_root_folder].nil? ? options[:clone_root_folder] : @fastlane_commons_dir_path

  keystore_folder = options[:folder]

  Dir.chdir(clone_root_folder) do
    sh("rm -r -f ./Android-Keystores")
    sh("git clone https://github.com/smartmobilefactory/Android-Keystores.git")
    sh("cd ./Android-Keystores; sh crypto.sh -decrypt #{keystore_folder}")
  end

  properties = load_properties("#{clone_root_folder}/Android-Keystores/keystores/#{keystore_folder}/keystore.properties")
  keystore_values = {}
  keystore_values[:keystore_file] = File.absolute_path("#{clone_root_folder}/Android-Keystores/keystores/#{keystore_folder}/keystore.jks")
  keystore_values[:keystore_password] = properties['KEYSTORE_PASSWORD']
  keystore_values[:keystore_key_alias] = properties['KEYSTORE_KEY_ALIAS']
  keystore_values[:keystore_key_password] = properties['KEYSTORE_KEY_PASSWORD']

  keystore_values
end

def load_properties(properties_filename)
  properties = {}
  File.open(properties_filename, 'r') do |properties_file|
    properties_file.read.each_line do |line|
      line.strip!
      next if !(line[0] != ?# && line[0] != ?=)

      i = line.index('=')
      if i
        properties[line[0..i - 1].strip] = line[i + 1..-1].strip
      else
        properties[line] = ''
      end
    end
  end

  properties
end