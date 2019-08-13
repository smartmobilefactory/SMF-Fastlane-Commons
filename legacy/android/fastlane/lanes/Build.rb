  ##################################
  ### smf_increment_build_number ###
  ##################################

desc "Increment Build Version Code"
private_lane :smf_increment_build_number do |options|

  build_variant = options[:build_variant]
  branch = options[:branch]

  smf_git_changelog(build_variant: build_variant)
  config = load_config()
  new_app_version_code = "0"
  if config
    config["app_version_code"] = config["app_version_code"] + 1
    update_config(config, "Increment build number to #{config["app_version_code"]}")
    new_app_version_code = config["app_version_code"].to_s
    # keep environment variable to be compatible
    ENV["next_version_code"] = new_app_version_code
  else
    # fallback to legacy module.properties handling
    smf_increment_build_number_properties(
      build_variant: build_variant,
      branch: branch,
      modulePropertiesFile: options[:modulePropertiesFile]
    )
    new_app_version_code = ENV["next_version_code"]
  end

  if git_tag_exists(tag: "v" + build_variant + new_app_version_code)
    UI.message("Git tag already existed")
  else
    add_git_tag(tag: 'v' + build_variant + new_app_version_code)
  end

  push_to_git_remote(
    remote: 'origin',
    local_branch: branch,
    remote_branch: branch,
    force: false,
    tags: true
  )
end

desc "Increment Build Version Code using the legacy module.properties file"
private_lane :smf_increment_build_number_properties do |options|

  build_variant = options[:build_variant]
  branch = options[:branch]

  modulePropertiesFile = options[:modulePropertiesFile]
  if !modulePropertiesFile
    modulePropertiesFile = "#{smf_workspace_dir}/app/module.properties"
  end

  # we need to switch the current dir (the fastlane folder) to its parent folder to have the correct path to the properties file. 
  # as all actions (for example "sh") are always performed on the root directory of the project and we don't want to specify the path to the properties
  # file twice, we just change the directory to the root directory and read the properties file
  properties = load_properties(modulePropertiesFile)

  UI.important("Increment Build Version Code")

  next_version_code = properties["app_version_code"].to_i + 1
  ENV["next_version_code"] = next_version_code.to_s

  # set new version code
  sh("awk -F\"=\" \'BEGIN{OFS=\"=\";} /app_version_code/{$2=\"#{next_version_code}\";print;next}1\' #{modulePropertiesFile} > #{modulePropertiesFile}_new")
  sh("rm #{modulePropertiesFile}")
  sh("mv #{modulePropertiesFile}_new #{modulePropertiesFile}")

  git_add(path: modulePropertiesFile)
  git_commit(path: modulePropertiesFile, message: "Increment build number to #{ENV["next_version_code"]}")
end

##############################
### smf_generate_meta_json ###
##############################

desc "Create and push the metaJSON files - should only be applied after Alpha builds."
private_lane :smf_generate_meta_json do |options|

  branch = options[:branch]

  begin
    gradle(task: "createClocJson")
    gradle(task: "createDependenciesJson")
    gradle(task: "createProjectJson")
  rescue
    UI.important("Seems like MetaJSON is not yet included in this project! Skipping lane!")
    next
  end

  something_to_commit = `git status --porcelain`.empty?
  if !something_to_commit
    git_add(path: "#{smf_workspace_dir}/.MetaJSON")
    git_commit(path: "#{smf_workspace_dir}/.MetaJSON", message: "Updated MetaJSON files")

    push_to_git_remote(
        remote: 'origin',
        local_branch: branch,
        remote_branch: branch,
        force: false
    )
  end
end

################################
### smf_upload_apk_to_hockey ###
################################

desc "Clean, build and release the app on HockeyApp"
private_lane :smf_upload_apk_to_hockey do |options|
  apkFile = options[:apkFile]
  apkPath = options[:apkPath]
  hockeyAppId = options[:hockeyAppId]

  if apkPath
    found = true
    apk_path = apkPath
  else
    found = false
    for apk_path in lane_context[SharedValues::GRADLE_ALL_APK_OUTPUT_PATHS]
      found = apk_path.include? apkFile
      if found
        break
      end
    end
  end
  UI.crash!("Cannot find the APK " + apkFile) if !found

  UI.important("Uploading to HockeyApp (id: \"#{hockeyAppId}\") apk: #{apk_path}")

  hockey(
    api_token: ENV["HOCKEYAPP_API_TOKEN"], # configured in jenkins
    apk: apk_path,
    public_identifier: hockeyAppId,
    notify: "0",
    notes: ENV["CHANGELOG"]
  )

  if Actions.lane_context[Actions::SharedValues::HOCKEY_BUILD_INFORMATION]['id'] > 1
    previous_version_id  = Actions.lane_context[Actions::SharedValues::HOCKEY_BUILD_INFORMATION]['id'] - 1

    UI.important("HERE IS THE ID OF THE Current VERSION #{Actions.lane_context[Actions::SharedValues::HOCKEY_BUILD_INFORMATION]['id']}")
    UI.important("HERE IS THE ID OF THE Previous VERSION #{previous_version_id}")

    begin
      disable_hockey_download(
        api_token: ENV["HOCKEYAPP_API_TOKEN"], # configured in jenkins
        public_identifier: hockeyAppId,
        version_id: "#{previous_version_id}"
      )
    rescue => ex
      UI.error("Something went wrong: #{ex}")
    end
  end

  # Inform the SMF HockeyApp about the new app version
  begin
    smf_notify_app_uploaded(
      hockeyapp_id: hockeyAppId
    )
  rescue
    UI.important("Warning: The APN to the SMF HockeyApp couldn't be sent!")
    next
  end

end

#######################
#### smf_build_apk ####
#######################

desc "Build the project based on the build type and flavor of the environment."
private_lane :smf_build_apk do |options|

  build_variant = options[:build_variant]

  if !build_variant
    UI.important("Building all variants")
    build_variant = ""
  else
    UI.important("Building variant " + build_variant)
  end

  addition = ""
  if ENV["KEYSTORE_FILE"]
    KEYSTORE_FILE = ENV["KEYSTORE_FILE"]
    KEYSTORE_PASSWORD = ENV["KEYSTORE_PASSWORD"]
    KEYSTORE_KEY_ALIAS = ENV["KEYSTORE_KEY_ALIAS"]
    KEYSTORE_KEY_PASSWORD = ENV["KEYSTORE_KEY_PASSWORD"]
    addition = " -Pandroid.injected.signing.store.file='#{KEYSTORE_FILE}'"
    addition << " -Pandroid.injected.signing.store.password='#{KEYSTORE_PASSWORD}'"
    addition << " -Pandroid.injected.signing.key.alias='#{KEYSTORE_KEY_ALIAS}'"
    addition << " -Pandroid.injected.signing.key.password='#{KEYSTORE_KEY_PASSWORD}'"
  end

  gradle(task: "assemble" + build_variant + addition)

end

###########################
#### smf_pull_keystore ####
###########################

desc "Pull Keystore from SMF Keystore Repository"
private_lane :smf_pull_keystore do |options|

  clone_root_folder = options[:clone_root_folder]
  if !clone_root_folder
    clone_root_folder = @fastlane_commons_dir_path
  end
  keystoreFolder = options[:folder]

  Dir.chdir(clone_root_folder) do
      sh("rm -r -f ./Android-Keystores")
      sh("git clone https://github.com/smartmobilefactory/Android-Keystores.git")
      sh("cd ./Android-Keystores; sh crypto.sh -decrypt #{keystoreFolder}")
  end

  properties = load_properties("#{clone_root_folder}/Android-Keystores/keystores/#{keystoreFolder}/keystore.properties")
  ENV["KEYSTORE_FILE"] = File.absolute_path("#{clone_root_folder}/Android-Keystores/keystores/#{keystoreFolder}/keystore.jks")
  ENV["KEYSTORE_PASSWORD"] = properties["KEYSTORE_PASSWORD"]
  ENV["KEYSTORE_KEY_ALIAS"] = properties["KEYSTORE_KEY_ALIAS"]
  ENV["KEYSTORE_KEY_PASSWORD"] = properties["KEYSTORE_KEY_PASSWORD"]
end

###############################
#### smf_release_playstore ####
###############################

desc "release the app on PlayStore"
private_lane :smf_release_playstore do |options|

  apkFile = options[:apkFile]
  track = options[:track]

  found = false
  for apk_path in lane_context[SharedValues::GRADLE_ALL_APK_OUTPUT_PATHS]
    found = apk_path.include? apkFile
    if found
      break
    end
  end

  supply(
    track: track,
    apk: apk_path,
    json_key: ENV["json_key"] # configured in jenkins
  )
end


##################################
#### smf_generate_screenshots ####
##################################

desc "generates localized screenshots"
private_lane :smf_generate_screenshots do |options|
  gradle(task: "assembleInternalDebug assembleAndroidTest")
  screengrab
end

