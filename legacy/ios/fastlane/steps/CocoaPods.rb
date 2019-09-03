####################
### smf_pod_push ###
####################

desc "Release a new Pod version"
private_lane :smf_pod_push do |options|

  # Variables 
  build_variant_config = @smf_fastlane_config[:build_variants][@smf_build_variant_sym]
  podspec_path = build_variant_config[:podspec_path]
  specs_repo = build_variant_config[:pods_specs_repo]
  workspace_dir = smf_workspace_dir

  smf_setup_correct_xcode_executable_for_build

  if specs_repo
    sh "cd #{workspace_dir}"
    pod_push(path: podspec_path, allow_warnings: true, skip_import_validation: true, repo: specs_repo)
  else
    sh "cd #{workspace_dir}"
    pod_push(path: podspec_path)
  end
end
