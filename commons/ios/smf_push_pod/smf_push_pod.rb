desc 'Release a new Pod version'
private_lane :smf_push_pod do |options|

  podspec_path = options[:podspec_path]
  specs_repo = options[:specs_repo]
  required_xcode_version = options[:required_xcode_version]
  local_branch = options[:local_branch]

  workspace_dir = smf_workspace_dir
  tag = smf_get_tag_of_pod(podspec_path)

  smf_setup_correct_xcode_executable_for_build(required_xcode_version: required_xcode_version)


  # Push the changes to a temporary branch, so the tag is pushed and can be used by smf_pod_push
  # otherwise pod_push fails because it can't find the remote branch associated with the tag
  smf_push_to_git_remote(
      local_branch: local_branch,
      remote_branch: "jenkins_build/#{local_branch}",
      force: true
  )

  begin
    # Try to Publish the pod. If it fails the temporary branch is deleted
    if specs_repo
      sh "cd #{workspace_dir}"
      pod_push(path: podspec_path, allow_warnings: true, skip_import_validation: true, repo: specs_repo)
    else
      sh "cd #{workspace_dir}"
      pod_push(path: podspec_path)
    end

  rescue => e
    _smf_delete_temp_branch(local_branch, tag)

    raise "Pod push failed: #{e.message}"
  end

  smf_push_to_git_remote

  _smf_delete_temp_branch(local_branch)
end

# Delets the temporary branch "jenkins_build/<local_branch>", if a tag is provided, the tag is also deleted
def _smf_delete_temp_branch(local_branch, tag = nil)
  sh "git push --delete origin #{tag} || true" if !tag.nil?
  sh "git push origin --delete jenkins_build/#{local_branch} || true"
end