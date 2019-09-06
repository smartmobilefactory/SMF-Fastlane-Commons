# Setup Dependencies - pod install & `sh generate.sh` (optional: Phrase App)
private_lane :super_setup_dependencies do |options|

  smf_pod_install
  smf_sync_with_phrase_app(@smf_fastlane_config[:build_variants][options[:build_variant].to_sym][:phrase_app])
end

lane :setup_dependencies do |options|
  super_setup_dependencies(options)
end

# Provisioning
private_lane :super_handle_provisioning_profiles do |options|

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
private_lane :super_pipeline_increment_build_number do |options|

  smf_increment_build_number(
      build_variant: options[:build_variant],
      current_build_number: smf_get_build_number_of_app
  )

end

lane :pipeline_increment_build_number do |options|
  super_pipeline_increment_build_number(options)
end

# build (build to release)

private_lane :super_build do |options|
  build_variant_config = @smf_fastlane_config[:build_variants][options[:build_variant].to_sym]
  smf_build_ios_app(
      scheme: build_variant_config[:scheme],
      should_clean_project: build_variant_config[:should_clean_project],
      required_xcode_version: @smf_fastlane_config[:project][:xcode_version],
      project_name: @smf_fastlane_config[:project][:project_name],
      xcconfig_name: smf_get_xcconfig_name(options[:build_variant].to_sym),
      code_signing_identity: build_variant_config[:code_signing_identity],
      upload_itc: build_variant_config[:upload_itc].nil? ? false : build_variant_config[:upload_itc],
      upload_bitcode: build_variant_config[:upload_bitcode].nil? ? true : build_variant_config[:upload_bitcode],
      export_method: build_variant_config[:export_method],
      icloud_environment: smf_get_icloud_environment(options[:build_variant].to_sym)
  )
end

lane :build do |options|
  super_build(options)
end

# changelog
private_lane :super_changelog do |options|
  smf_git_changelog(build_variant: options[:build_variant])
end

lane :changelog do |options|
  super_changelog(options)
end

# Upload Dsym
private_lane :super_upload_dsyms do |options|

  build_variant_config = @smf_fastlane_config[:build_variants][options[:build_variant].to_sym]

  smf_upload_to_sentry(
    build_variant: options[:build_variant],
    org_slug: @smf_fastlane_config[:sentry_org_slug],
    project_slug: @smf_fastlane_config[:sentry_project_slug],
    build_variant_org_slug: build_variant_config[:sentry_org_slug],
    build_variant_project_slug: build_variant_config[:sentry_project_slug]
  )

end

lane :upload_dsyms do |options|
  super_upload_dsyms(options)
end
# Upload Appcenter
# Upload iTunes
# Push git tag / Release
# Slack
# Monitoring (MetaJSON)