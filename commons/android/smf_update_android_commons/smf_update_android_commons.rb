private_lane :smf_update_android_commons do |options|

  UI.user_error!("android-commons not present!") if !File.exist?('../android-commons')

  android_commons_branch = !options[:android_commons_branch].nil? ? options[:android_commons_branch] : 'master'

  puts ('Update Android Commons from branch ' + android_commons_branch)
  Dir.chdir("#{smf_workspace_dir}/android-commons") do
    sh('git checkout ' + android_commons_branch)
    sh('git pull')
  end

  # update JenkinsFile
  _smf_update_jenkins_file

  something_to_commit = false
  Dir.chdir(smf_workspace_dir) do
    # execute from root folder
    something_to_commit = !`git status --porcelain`.empty?
  end

  if something_to_commit
    branch = git_branch
    sh('git', 'fetch')
    sh('git', 'checkout', branch)
    sh('git', 'pull')
    git_add(path: '.')
    git_commit(path: '.', message: 'Updated android-commons')

    smf_push_to_git_remote(remote_branch: ENV['CHANGE_BRANCH'])

    UI.message('Android-Commons updated.')

    # mark pr as failed
    # pull request will be checked again due to updated android-commons
    UI.user_error!('Android Commons Module updated.')
  else
    UI.message('Android Commons already up to date.')
  end
end

def _smf_update_jenkins_file

  if @smf_fastlane_config[:project][:type] == 'framework'
    # generate framework Jenkinsfile
    jenkins_file_data = File.read("#{@fastlane_commons_dir_path}/jenkins/Jenkinsfile_Android_Framework.template")
  else
    # generate app Jenkinsfile
    jenkins_file_data = File.read("#{@fastlane_commons_dir_path}/jenkins/Jenkinsfile_Android.template")
    UI.message(@smf_fastlane_config[:build_variants].keys)
    jenkins_file_data = jenkins_file_data.gsub('__BUILD_VARIANTS__', @smf_fastlane_config[:build_variants].keys)
  end
  File.write("#{smf_workspace_dir}/Jenkinsfile", jenkins_file_data)
end