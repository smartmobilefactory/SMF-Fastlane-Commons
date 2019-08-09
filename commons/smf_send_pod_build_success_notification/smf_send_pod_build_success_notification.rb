private_lane :smf_send_pod_build_success_notification do |options|

  build_variant = options[:build_variant]
  podspec_path = @smf_fastlane_config[:build_variants][@smf_build_variant_sym][:podspec_path]
  version = read_podspec(path: podspec_path)["version"]
  pod_name = read_podspec(path: podspec_path)["name"]
  project_name = !@smf_fastlane_config[:project][:project_name].nil? ? @smf_fastlane_config[:project][:project_name] : pod_name

  smf_default_build_success_notification("🎉🛠 Successfully built #{project_name} #{version} 🛠🎉", build_variant)
end