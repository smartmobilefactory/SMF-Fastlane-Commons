# Setup Dependencies - pod install & `sh generate.sh` (optional: Phrase App)
private_lane :super_setup_dependencies do |options|

  smf_pod_install
  smf_sync_with_phrase_app(@smf_fastlane_config[:build_variants][options[:build_variant].to_sym][:phrase_app])
end

lane :setup_dependencies do |options|
  super_setup_dependencies(options)
end

# Provisioning
lane :super_handle_provisioning_profiles do |options|

  build_variant_config = @smf_fastlane_config[:build_variants][options[:build_variant].to_sym]

  smf_download_provisioning_profiles(
      team_id: build_variant_config[:team_id],
      apple_id: build_variant_config[:apple_id],
      use_wildcard_signing: build_variant_config[:use_wildcard_signing],
      bundle_identifier: build_variant_config[:bundle_identifier],
      use_default_match_config: build_variant_config[:match].nil?,
      match_read_only: build_variant_config[:match].nil? ? nil : build_variant_config[:match][:read_only],
      match_type: build_variant_config[:match].nil? ? nil : build_variant_config[:match][:type],
      extensions_suffixes: @smf_fastlane_config[:extensions_suffixes],
      build_variant: options[:build_variant]
  )
end

lane :handle_provisioning_profiles do |options|
  super_handle_provisioning_profiles(options)
end

# increment_buildnumber
lane :super_increment_build_number do |options|

  smf_increment_build_number(
      build_variant: options[:build_variant],
      current_build_number: get_build_number_of_app
  )

end

lane :increment_build_number do |options|
  super_increment_build_number(options)
end

# build (build to release)
# changelog
# Upload Dsym
# Upload Appcenter
# Upload iTunes
# Push git tag / Release
# Slack
# Monitoring (MetaJSON)