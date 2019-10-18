desc 'Release a new Pod version'
private_lane :smf_push_pod do |options|

  podspec_path = options[:podspec_path]
  specs_repo = options[:pods_specs_repo]
  workspace_dir = smf_workspace_dir
  required_xcode_version = options[:required_xcode_version]

  smf_setup_correct_xcode_executable_for_build(required_xcode_version: required_xcode_version)

  if specs_repo
    sh "cd #{workspace_dir}"
    pod_push(path: podspec_path, allow_warnings: true, skip_import_validation: true, repo: specs_repo)
  else
    sh "cd #{workspace_dir}"
    pod_push(path: podspec_path)
  end
end