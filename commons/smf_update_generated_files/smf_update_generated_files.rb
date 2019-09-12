desc "Generates a Jenkinsfile and commits it if there are changes"
private_lane :smf_update_generated_files do |options|

    branch = options[:branch]

    smf_generate_jenkins_file

    jenkinsfile_changed = false
    Dir.chdir(smf_workspace_dir) do
      jenkinsfile_changed = `git status --porcelain`.include? 'Jenkinsfile'
    end

    UI.message('Checking for Jenkinsfile changes...')

    # If something changed in config
    if jenkinsfile_changed
      UI.message('Jenkinsfile changed since last build, will synchronize and commit the changes...')

      git_add(path: './Jenkinsfile')
      git_commit(path: '.', message: 'Updated Generated Jenkinsfile')

      unlock_keychain(path: 'login.keychain', password: ENV['LOGIN'])
      unlock_keychain(path: 'jenkins.keychain', password: ENV['JENKINS'])

      smf_push_to_git_remote(remote_branch: branch)

      UI.user_error!('Generated Jenkinsfile changed since last build, build will be restarted. This is not a failure.')
    else
      UI.success('Generated Jenkinsfile is up to date. Nothing to do.')
    end
end
