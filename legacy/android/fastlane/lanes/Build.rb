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
  unless something_to_commit
    git_add(path: "#{smf_workspace_dir}/.MetaJSON")
    git_commit(path: "#{smf_workspace_dir}/.MetaJSON", message: "Updated MetaJSON files")

    smf_push_to_git_remote(local_branch: branch)
  end
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

