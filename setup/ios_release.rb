lane :test_lane do

  UI.message("This is a test")
end

# Setup Dependencies - pod install & `sh generate.sh` (optional: Phrase App)
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