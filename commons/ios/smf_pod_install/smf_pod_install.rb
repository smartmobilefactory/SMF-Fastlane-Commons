desc "Runs pod install if the project contains a Podfile"
private_lane :smf_pod_install do |options|

  podfile = "#{smf_workspace_dir}/Podfile"
  File.exist?(podfile) ? cocoapods(podfile: podfile) : UI.message("Didn't install Pods as the project doesn't contain a Podfile")
end