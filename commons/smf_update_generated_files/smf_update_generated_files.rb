desc "Generates a Jenkinsfile (and optional additional files) and commits them if there are changes"
private_lane :smf_update_generated_files do |options|

  ios_build_nodes = options[:ios_build_nodes]

  additional_files_to_update = options[:files_to_update].nil? ? [] : options[:files_to_update]

  _smf_update_jenkins_file(ios_build_nodes)

  additional_files_to_update.each do |file_data|
    smf_generate_jenkins_file(
      ios_build_nodes: ios_build_nodes,
      custom_jenkinsfile_template: file_data[:template],
      custom_jenkinsfile_path: file_data[:file],
      remove_multibuild_variants: file_data[:remove_multibuilds]
    )

    if (_smf_generated_file_changed?(file_data[:file]))
      _smf_commit_generated_file(file_data[:file], false)
    end
  end

end

def _smf_update_jenkins_file(ios_build_nodes)
  UI.message('Checking for Jenkinsfile changes...')
  # JENKINSFILE is always updated
  jenkinsfile_path = File.join(smf_workspace_dir, 'Jenkinsfile')

  smf_generate_jenkins_file(
    ios_build_nodes: ios_build_nodes
  )

  if (_smf_generated_file_changed?(jenkinsfile_path))
    _smf_commit_generated_file(jenkinsfile_path)
  else
    UI.success('Generated Jenkinsfile is up to date. Nothing to do.')
  end
end

def _smf_generated_file_changed?(path)
  path = path.sub(smf_workspace_dir + '/', '')
  file_changed = false
  Dir.chdir(smf_workspace_dir) do
    file_changed = `git status --porcelain`.include?(path)
  end

  file_changed
end

def _smf_commit_generated_file(path, fail_build = true)
  file_name = File.basename(path)
  UI.message("#{file_name} changed since last build, will synchronize and commit the changes...")

  git_add(path: path)
  git_commit(path: path, message: "Updated Generated File: #{file_name}")

  unlock_keychain(path: 'login.keychain', password: ENV[$KEYCHAIN_LOGIN_ENV_KEY])
  unlock_keychain(path: 'jenkins.keychain', password: ENV[$KEYCHAIN_JENKINS_ENV_KEY])

  smf_push_to_git_remote(remote_branch: ENV['CHANGE_BRANCH'])

  if (fail_build)
    UI.error("Generated File: #{file_name} changed since last build, build will be restarted. This is not a failure.")
    raise "#{file_name} changed, restarting buildjob 🔄"
  end
end
