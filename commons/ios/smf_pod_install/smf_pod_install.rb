desc "Runs pod install if the project contains a Podfile"
private_lane :smf_pod_install do |options|

  podfile = options[:podfile_path].nil? ? "#{smf_workspace_dir}/Podfile" : options[:podfile_path]

  if File.exist?(podfile)
    cocoapods(
        podfile: podfile,
        try_repo_update_on_error: true
    )
  else
    UI.message("Didn't install Pods as the project doesn't contain a Podfile")
  end
end