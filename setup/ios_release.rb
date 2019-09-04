# Setup Dependencies - pod install & `sh generate.sh` (optional: Phrase App)
private_lane :super_setup_dependencies do |options|

  smf_pod_install

  UI.message("Reading Config.json at #{smf_workspace_dir}/Config.json")
  config = JSON.parse(File.read("#{smf_workspace_dir}/Config.json"), :symbolize_names => true)
  phrase_app_properties = config[:build_variants][options[:build_variant].to_sym][:phrase_app]

  smf_sync_with_phrase_app(phrase_app_properties)
end

lane :setup_dependencies do |options|
  super_setup_dependencies(options)
end

# Provisioning
lane :super_handle_provisioning_profiles do |options|

  UI.message("Reading Config.json at #{smf_workspace_dir}/Config.json")
  config = JSON.parse(File.read("#{smf_workspace_dir}/Config.json"), :symbolize_names => true)
  build_variant_config = config[:build_variants][options[:build_variant].to_sym]

  smf_download_provisioning_profiles(
      team_id: build_variant_config[:team_id],
      apple_id: build_variant_config[:apple_id],
      use_wildcard_signing: build_variant_config[:use_wildcard_signing],
      bundle_identifier: build_variant_config[:bundle_identifier],
      use_default_match_config: build_variant_config[:match].nil?,
      match_read_only: build_variant_config[:match][:read_only],
      match_type: build_variant_config[:match][:type],
      extensions_suffixes: config[:extensions_suffixes]
  )
end

lane :handle_provisioning_profiles do |options|
  super_handle_provisioning_profiles(options)
end
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