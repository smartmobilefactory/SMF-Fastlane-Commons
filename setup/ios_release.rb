# Setup Dependencies - pod install & `sh generate.sh` (optional: Phrase App)
private_lane :super_setup_dependencies do |options|
  UI.message("Reading Config.json at #{smf_workspace_dir}/Config.json")
  sh("cd #{smf_workspace_dir}; ls -a")
  phrase_app_properties = JSON.parse(File.read("#{smf_workspace_dir}/Config.json"), :symbolize_names => true)[options[:build_variant].to_sym][:phrase_app]
  smf_pod_install
  UI.message("properties: #{phrase_app_properties}")
  smf_sync_with_phrase_app(phrase_app_properties)
end

lane :setup_dependencies do |options|
  super_setup_dependencies
end
# Provisioning
# run unittests (build test target and run test)
# increment_buildnumber
# build (build to release)
# changelog
# Upload Dsym
# Upload Appcenter
# Upload iTunes
# Push git tag / Release
# Slack
# Monitoring (MetaJSON)