###########################
### smf_pr_check ###
###########################
# options: 
#   danger: Map of danger options (see DangerFastfile)
###########################

fastlane_require 'json'

desc "Run checks, build project and report with Danger"
private_lane :smf_pr_check do |options|

  UI.important("Pullrequest Checks")

  smf_update_android_commons()

  danger_config = options[:danger] || {}

  config = load_config()
  smf_danger_build_pr(
    jira_key: config["project"]["jira_key"],
    gradle_lint_task: danger_config["gradle_lint_task"],
    gradle_build_task: danger_config["gradle_build_task"],
    module_basepath: danger_config["module_basepath"],
    run_detekt: danger_config["run_detekt"],
    junit_task: danger_config["junit_task"],
    modules: danger_config["modules"]
  )
end

desc "Update Android Commons"
private_lane :smf_update_android_commons do |options|

  UI.user_error!("android-commons not present! Can't start danger") if !File.exist?("../android-commons")

  # Update android-commons and push to remote
  # using the built in git features from fastlane doesn't work because they are working on the root repository 

  android_commons_branch = "master"
  if ENV["android_commons_branch"]
    android_commons_branch = ENV["android_commons_branch"]
  end

  puts ("Update android-commons from branch " + android_commons_branch)
  Dir.chdir("#{smf_workspace_dir}/android-commons") do
    sh("git checkout " + android_commons_branch)
    sh("git pull")
  end

  # update JenkinsFile
  smf_update_jenkins_file

  something_to_commit = false
  Dir.chdir(smf_workspace_dir) do
    # execute from root folder
    something_to_commit = !`git status --porcelain`.empty?
  end

  if something_to_commit
    branch = git_branch
    sh("git", "fetch")
    sh("git", "checkout", branch)
    sh("git", "pull")
    git_add(path: '.')
    git_commit(path: '.', message: "Updated android-commons")

    smf_push_to_git_remote(remote_branch: ENV["CHANGE_BRANCH"])

    puts "android-commons updated"

    # mark pr as failed
    # pull request will be checked again due to updated android-commons
    UI.user_error!("Android Commons Module updated")
  else
    puts "android-commons already up-to-date"
  end
end

desc "Update Jenkinsfile"
private_lane :smf_update_jenkins_file do |options|
  config = load_config()
  if !config
    UI.user_error!("Config.json not found")
  end

  if config["project"]["type"] == "framework"
    # generate framework Jenkinsfile
    jenkinsFileData = File.read("#{@fastlane_commons_dir_path}/jenkins/Jenkinsfile_Android_Framework.template")
    File.write("#{smf_workspace_dir}/Jenkinsfile", jenkinsFileData)
  else
    # generate app Jenkinsfile
    jenkinsFileData = File.read("#{@fastlane_commons_dir_path}/jenkins/Jenkinsfile_Android.template")
    jenkinsFileData = jenkinsFileData.gsub("__BUILD_VARIANTS__", JSON.dump(config["build_variants"]))
    File.write("#{smf_workspace_dir}/Jenkinsfile", jenkinsFileData)
  end
end


