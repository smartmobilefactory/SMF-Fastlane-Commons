# Setup Dependencies - pod install & `sh generate.sh` (optional: Phrase App)
private_lane :super_setup_dependencies do |options|
  smf_pod_install
  smf_sync_with_phrase_app(get_phrase_app_properties)
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