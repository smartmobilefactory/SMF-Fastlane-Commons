# Uses Config file to access project name. Should be changed in the future.
def get_default_name_of_pod
  podspec_path = @smf_fastlane_config[:build_variants][@smf_build_variant_sym][:podspec_path]
  version = read_podspec(path: podspec_path)['version']
  pod_name = read_podspec(path: podspec_path)['name']
  project_name = !@smf_fastlane_config[:project][:project_name].nil? ? @smf_fastlane_config[:project][:project_name] : pod_name
  "#{project_name} #{version}"
end

def get_tag_of_pod(version_number)
  "releases/#{version_number}"
end

def smf_is_keychain_enabled
  return ENV[$SMF_IS_KEYCHAIN_ENABLED].nil? ? true : ENV[$SMF_IS_KEYCHAIN_ENABLED] == "true"
end

def get_extension_suffixes
  @smf_fastlane_config[:extensions_suffixes]
end

def get_required_xcode_version
  @smf_fastlane_config[:project][:xcode_version]
end

def get_sentry_org_slug
  @smf_fastlane_config[:sentry_org_slug]
end

def get_sentry_project_slug
  @smf_fastlane_config[:sentry_project_slug]
end

##################################
###    Build variant config    ###
##################################
def build_variant_config
  @smf_fastlane_config[:build_variants][@smf_build_variant_sym]
end

def get_build_scheme
  build_variant_config[:scheme]
end

def get_target
  build_variant_config[:target]
end

def get_upload_itc
  build_variant_config[:upload_itc].nil? ? false : build_variant_config[:upload_itc]
end

def get_upload_bitcode
  build_variant_config[:upload_bitcode].nil? ? true : build_variant_config[:upload_bitcode]
end

def get_use_xcconfig
  build_variant_config[:xcconfig_name].nil? ? false : true
end

def get_xcconfig_name
  use_xcconfig = build_variant_config[:xcconfig_name].nil? ? false : true
  use_xcconfig ? build_variant_config[:xcconfig_name][:archive] : "Release"
end

def get_export_method
  build_variant_config[:export_method]
end

def get_icloud_environment
  build_variant_config[:icloud_environment].nil? ? "Development" : build_variant_config[:icloud_environment]
end

def get_code_signing_identity
  build_variant_config[:code_signing_identity]
end

def get_use_sparkle
  build_variant_config[:use_sparkle].nil? ? false : build_variant_config[:use_sparkle]
end

def get_use_wildcard_signing
  build_variant_config[:use_wildcard_signing]
end

def get_team_id
  build_variant_config[:team_id]
end

def get_apple_id
  build_variant_config[:apple_id]
end

def get_bundle_identifier
  build_variant_config[:bundle_identifier]
end

def get_is_adhoc_build
  @smf_build_variant.include? "adhoc"
end

def get_itc_team_id
  build_variant_config[:itc_team_id]
end

def get_itc_skip_version_check
  build_variant_config[:itc_skip_version_check]
end

def get_itc_apple_id
  build_variant_config[:itc_apple_id]
end

def match_config
  build_variant_config[:match]
end

def get_match_config_read_only
  match_config.nil? ? nil : match_config[:read_only]
end

def get_match_config_type
  match_config.nil? ? nil : match_config[:type]
end

def get_should_clean_project
  build_variant_config[:should_clean_project]
end

def get_escaped_filename(build_variant)
  @smf_fastlane_config[:build_variants][build_variant.to_sym][:scheme].gsub(' ', "\ ")
end

def is_mac_app(build_variant)
  @smf_fastlane_config[:build_variants][build_variant.to_sym][:use_sparkle]
end

def get_variant_sentry_org_slug(build_variant)
  @smf_fastlane_config[:build_variants][build_variant.to_sym][:sentry_org_slug]
end

def get_variant_sentry_project_slug(build_variant)
  @smf_fastlane_config[:build_variants][build_variant.to_sym][:sentry_project_slug]
end

def get_itc_apple_id(build_variant)
  @smf_fastlane_config[:build_variants][build_variant.to_sym][:itc_apple_id]
end

def get_itc_team_id(build_variant)
  @smf_fastlane_config[:build_variants][build_variant.to_sym][:itc_team_id]
end

def should_skip_waiting_after_itc_upload(build_variant)
  !@smf_fastlane_config[:build_variants][build_variant.to_sym][:itc_skip_waiting].nil? ? @smf_fastlane_config[:build_variants][build_variant.to_sym][:itc_skip_waiting] : false
end

def get_path_to_ipa_or_app(build_variant)

  escaped_filename = get_escaped_filename(build_variant)

  app_path = Pathname.getwd.dirname.to_s + "/build/#{escaped_filename}.app.zip"
  app_path = Pathname.getwd.dirname.to_s + "/build/#{escaped_filename}.app" unless File.exist?(app_path)

  UI.message("Constructed path \"#{app_path}\" from filename \"#{escaped_filename}\"")

  unless File.exist?(app_path)
    app_path = lane_context[SharedValues::IPA_OUTPUT_PATH]

    UI.message("Using \"#{app_path}\" as app_path as no file exists at the constructed path.")
  end

  app_path
end

def get_podspec_path(build_variant)
  @smf_fastlane_config[:build_variants][build_variant.to_sym][:podspec_path]
end

def smf_get_version_number
  version_number = get_version_number(
      xcodeproj: "#{get_project_name}.xcodeproj",
      target: (get_target != nil ? get_target : get_build_scheme)
  )

  return version_number
end


def ci_android_error_log
  $SMF_CI_ANDROID_ERROR_LOG.to_s
end
