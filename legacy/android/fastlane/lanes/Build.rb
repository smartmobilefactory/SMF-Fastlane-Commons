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

