lane :smf_sync_with_phrase_app do |options|
  case @platform
  when :ios
    initialize_env_variable_name_mappings
    UI.message("Strings are synced with PhraseApp using the values from the fastlane/Config.json")

    if (!validate_and_set_phrase_app_env_variables(options))
      UI.message("Either phrase app is not used in this project or you have to check the fastlane/Config.json \"phrase_app\" entries for completeness!")
      next
    end

    UI.message("Starting to clone Phraseapp-CI scripts...")
    phrase_app_scripts_path = clone_phraseapp_ci
    raise ("PhraseApp scripts path is nil") if phrase_app_scripts_path.nil?

    UI.message("Successfully downloaded phrase app scripts, running scripts...")
    sh "if #{phrase_app_scripts_path}/push.sh; then #{phrase_app_scripts_path}/pull.sh || true; fi"

    UI.message("Ran scripts.. checking for extensions...")
    extensions = check_for_extensions_and_validate(options)

    if (extensions == [])
      UI.message("There are no extension entries..")
    else
      UI.message("Found extensions...")
      extensions.each do |extension|
        if (extension != nil)
          setup_environment_variables_for_extension(extension)
          sh "if #{phrase_app_scripts_path}/push.sh; then #{phrase_app_scripts_path}/pull.sh || true; fi"
        elsif
        UI.message("Skipping invalid extension.. look in the Config.json if all extension have the mandatory entries.")
        end
      end
    end

    UI.message("Finished executing phrase app scripts for extensions...")
    UI.message("Deleting phrase app ci scripts...")
    clean_up_phraseapp_ci(phrase_app_scripts_path)
  when :android
    UI.message('Sync string with PhraseApp for android is implemented as fastlane action and should be overwritten in the projects fastfile.')
  when :flutter
    UI.message('Sync string with PhraseApp for flutter is not implemented yet')
  else
    UI.message("There is no platform \"#{@platform}\", exiting...")
    raise 'Unknown platform'
  end
end

# Mapps the keys of the fastlane/Config.json to the env. variable names of the phrase app script
# the boolean value indicates whether the value is optional or not
# for default values a third entry in the array can be provided

def initialize_env_variable_name_mappings
  @phrase_app_config_keys_env_variable_mapping = {
      :access_token_key           => ["phraseappAccessToken", true, $SMF_PHRASE_APP_ACCESS_TOKEN_KEY], # optional
      :project_id                 => ["phraseappProjectId", false],
      :source                     => ["phraseappSource", false],
      :locales                    => ["phraseappLocales", false],
      :format                     => ["phraseappFormat", false],
      :base_directory             => ["phraseappBasedir", false],
      :files                      => ["phraseappFiles", false],
      :git_branch                 => ["phraseappGitBranch", true, @smf_git_branch],  # optional, defaults to @smf_git_branch
      :files_prefix               => ["phraseappFilesPrefix", true, ""], # optional
      :forbid_comments_in_source  => ["phraseappForbidCommentsInSource", true, "1"]  # optional
  }
end

# Validates that all necessary values are present in the fastlane/Config.json
# if a none optional value is missing, no env are set and false is returned
# otherwise the environment variables are set and true is returned
def validate_and_set_phrase_app_env_variables(options)
  export_env_key_value_pairs = {}

  UI.message("Checking if all necessary values for the phrase app script are present in the Config.json...")

  @phrase_app_config_keys_env_variable_mapping.each do |key, value|
    result = validate_phrase_app_variable(key, value[1], options)
    if (result == nil)
      return false
    end

    export_env_key_value_pairs[value[0]] = result
  end

  UI.message("Successfully checked values necessary for phrase app script 🎉")
  UI.message("Setting environment variables...")

  export_dict_as_env_variables(export_env_key_value_pairs)

  return true
end

# Checks if the value for a given key exists in the fastlane config.json file,
# if the value doesn't exist and the value is mandatory it returns nil
# if the value doesnt' exist and the value is optional it returns the default value
# otherwise it returns the value found for the given key.
def validate_phrase_app_variable(key, optional, options)
  value = options[key]
  if (value == nil) && (optional == false)
    UI.error("Failed to get phraseapp value for key #{key} in config.json")
    return nil
  elsif (value == nil) && (optional == true)
    UI.message("Couldn't find value for key #{key}, for the phrase-app script. Default is: \"#{@phrase_app_config_keys_env_variable_mapping[key][2]}\"")
    return @phrase_app_config_keys_env_variable_mapping[key][2]
  elsif (value != nil)
    value = transform_value_if_necessary(key, value)
    UI.message("Phrase script value for key #{key} is #{value}")
    return value
  end

  return nil
end

######################### HANDLE EXTENSIONS ##########################

# Checks if there are any extensions to run the phrase app scripts with
# and validates that all necessary entries are present
# returns an array with extensions if valid ones are found
# invalid ones are put as nil into the array
# otherwise returns an emtpy array if no extensions are present
def check_for_extensions_and_validate(options)
  extensions = options[:extensions]
  validated_extensions = []
  if (extensions != nil) && (extensions.length != 0)
    extensions.each do |extension|
      validated_extension = validate_extension(extension)
      validated_extensions.push(validated_extension)

      if (validated_extension == nil)
        UI.error("Error validating an extension entry in the fastlane/Config.json for the phrase app script")
      end
    end
  end

  return validated_extensions
end

# Goes through all the values in an extension
# and checks if they are present, if one is missing it returns nil
# otherwise it returns a dict with transformed key/values to be exported as env variables
def validate_extension(extension)
  exportable_extension = {}
  important_keys = [:project_id, :base_directory, :files]

  important_keys.each do |key|
    value = extension[key]
    env_key = @phrase_app_config_keys_env_variable_mapping[key][0]
    if (value == nil || env_key == nil)
      UI.error("Error validating a value in an extension...")
      return nil
    else
      value = transform_value_if_necessary(key, value)
      exportable_extension[env_key] = value
    end
  end

  return exportable_extension
end

def setup_environment_variables_for_extension(extension)
  export_dict_as_env_variables(extension)
end

############################# GIT AND GETTING THE PRHASE APP SCRIPTS ###########

# clones the phrasapp ci repository into the current directory
# so the push and pull scripts can be used
# returns parent directory of the push/pull scripts on success
# returns nil on error
def clone_phraseapp_ci
  url = $SMF_PHRASE_APP_SCRIPTS_REPO_URL
  branch = 'master'
  src_root = File.join(smf_workspace_dir, File.basename(url, File.extname(url)))
  if File.exists?(src_root)
    UI.error("Can't clone into #{src_root}, directory already exists. Can't download Phraseapp-CI scripts..")
    return nil
  end
  UI.message("Cloning #{url} branch: #{branch} into #{src_root}")
  `git clone #{url} #{src_root} -b #{branch} -q > /dev/null`
  if File.exists?(src_root) == false
    UI.error("Error while cloning into #{src_root}. Couldn't download Phraseapp-CI scripts..")
    return nil
  end
  return src_root
end

def clean_up_phraseapp_ci(path)
  sh "rm -rf #{path}"
end

############################# HELPERS #################################

# Transform value to correct format to export as env variable
def transform_value_if_necessary(key, value)
  case key
  when :access_token_key
    if value != $SMF_PHRASE_APP_ACCESS_TOKEN_KEY
      return ENV[$SMF_PHRASE_APP_CUSTOM_TOKEN_KEY]
    else
      return ENV[$SMF_PHRASE_APP_ACCESS_TOKEN_KEY]
    end
  when :locales, :files
    return value.join(" ")
  when :forbid_comments_in_source
    if (value == true)
      return "1"
    else
      return "0"
    end
  else
    return value
  end
end

# export dict as environment variables
def export_dict_as_env_variables(dict)
  dict.each do |key, value|
    if (value != nil)
      ENV[key] = value
    end
  end
end
