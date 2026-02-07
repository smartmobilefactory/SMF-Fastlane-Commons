private_lane :smf_build_apple_app do |options|

  UI.important("Creating the Xcode archive")

  # clean build directory
  UI.message('Cleaning build directory')
  `rm -rf #{smf_workspace_dir}/build`

  # Parameter
  skip_package_ipa = (options[:skip_export].nil? ? false : options[:skip_export])
  skip_package_pkg = (options[:skip_package_pkg].nil? ? true : options[:skip_package_pkg])
  bulk_deploy_params = options[:bulk_deploy_params]
  scheme = options[:scheme]
  should_clean_project = options[:should_clean_project]
  required_xcode_version = options[:required_xcode_version]
  project_name = options[:project_name]
  xcconfig_name = options[:xcconfig_name]
  code_signing_identity = options[:code_signing_identity]
  upload_itc = options[:upload_itc].nil? ? false : options[:upload_itc]
  upload_bitcode = options[:upload_bitcode].nil? ? true : options[:upload_bitcode]
  export_method = options[:export_method]
  icloud_environment = options[:icloud_environment]
  workspace = options[:workspace]
  build_variant = options[:build_variant]
  build_number = options[:build_number]
  bundle_identifier = options[:bundle_identifier]
  match_type = options[:match_type]

  catalyst_platform = nil
  if @platform == :apple
    catalyst_platform = 'ios'
    catalyst_platform = 'macos' if smf_is_catalyst_mac_build(build_variant)
  end

  output_name = scheme

  # Check if the project defined if the build should be cleaned. Other wise the default behavior is used based on the whether the archiving is a bulk operation.
  clean_project = !bulk_deploy_params.nil? ? (bulk_deploy_params[:index] == 0 && bulk_deploy_params[:count] > 1) : true

  clean_project = should_clean_project if should_clean_project != nil

  unlock_keychain(path: "jenkins.keychain", password: ENV[$KEYCHAIN_JENKINS_ENV_KEY]) if smf_is_keychain_enabled

  smf_setup_correct_xcode_executable_for_build(required_xcode_version: required_xcode_version)

  # Build xcargs string with optional build number override (CBENEFIOS-2077)
  xcargs_string = "#{smf_xcargs_for_build_system} CODE_SIGN_STYLE=Manual -skipPackagePluginValidation"
  if build_number
    UI.message("🔢 Overriding CURRENT_PROJECT_VERSION with: #{build_number}")
    xcargs_string += " CURRENT_PROJECT_VERSION=#{build_number}"
  end

  # CBENEFIOS-2059: Determine provisioning profile name and update Xcode project
  # We use update_code_signing_settings instead of xcargs PROVISIONING_PROFILE_SPECIFIER
  # because xcargs applies to ALL targets including SPM packages, which don't support provisioning profiles
  profile_name = nil
  if bundle_identifier && match_type
    # Match sets ENV variables in format: sigh_<bundle_id>_<type>_profile-name
    # Example: sigh_com.corporatebenefits.de.alpha_adhoc_profile-name
    profile_env_key = "sigh_#{bundle_identifier}_#{match_type}_profile-name"
    profile_name = ENV[profile_env_key]

    if profile_name && !profile_name.empty?
      UI.message("🔐 Using provisioning profile from match ENV: #{profile_name}")
    else
      # Fallback: Construct profile name for skip_match scenarios where ENV is not set
      # Match always uses naming convention: "match <Type> <bundle_identifier>"
      type_name = case match_type.to_s.downcase
                  when 'adhoc' then 'AdHoc'
                  when 'appstore' then 'AppStore'
                  when 'development' then 'Development'
                  when 'enterprise' then 'InHouse'
                  when 'developer_id' then 'Direct'
                  else match_type.to_s.split('_').map(&:capitalize).join('')
                  end
      profile_name = "match #{type_name} #{bundle_identifier}"
      UI.message("🔐 Using constructed provisioning profile name: #{profile_name}")
    end

    # Determine project path (handle workspace vs project scenarios)
    project_path = "#{project_name}.xcodeproj"
    if workspace && !workspace.empty?
      # Extract project path from workspace path for Flutter/workspace scenarios
      workspace_dir = File.dirname(workspace)
      potential_path = "#{workspace_dir}/#{project_name}.xcodeproj"
      project_path = potential_path if File.exist?(potential_path)
    end

    if File.exist?(project_path)
      UI.message("🔧 Updating code signing settings in Xcode project: #{project_path}")
      update_code_signing_settings(
        path: project_path,
        use_automatic_signing: false,
        bundle_identifier: bundle_identifier,
        profile_name: profile_name,
        code_sign_identity: code_signing_identity
      )
    else
      UI.important("⚠️  Project not found at #{project_path} - skipping update_code_signing_settings")
    end
  else
    UI.message("ℹ️  bundle_identifier or match_type not provided - using Xcode project defaults")
  end

  # Build export_options with provisioning profile mapping (for IPA export)
  export_opts = { iCloudContainerEnvironment: icloud_environment }
  if bundle_identifier && profile_name
    export_opts[:provisioningProfiles] = { bundle_identifier => profile_name }
  end

  gym_parameters = {
    clean: clean_project,
    workspace: !workspace.nil? ? workspace : "#{project_name}.xcworkspace",
    scheme: scheme,
    configuration: xcconfig_name,
    codesigning_identity: code_signing_identity,
    output_directory: $IOS_BUILD_OUTPUT_DIR,
    xcargs: xcargs_string,
    archive_path: $IOS_ARCHIVE_PATH,
    derived_data_path: $IOS_DERIVED_DATA_PATH,
    result_bundle: true,
    result_bundle_path: $IOS_RESULT_BUNDLE_PATH,
    buildlog_path: $IOS_ARCHIVE_BUILD_LOGS_DIRECTORY,
    output_name: output_name,
    include_symbols: true,
    include_bitcode: (upload_itc && upload_bitcode),
    export_options: export_opts,
    export_method: export_method,
    skip_package_ipa: skip_package_ipa,
    skip_package_pkg: skip_package_pkg,
    catalyst_platform: catalyst_platform
  }

  gym_parameters[:destination] = 'platform=macOS,variant=Mac Catalyst' if smf_is_catalyst_mac_build(build_variant)

  gym(gym_parameters)

end

def smf_xcargs_for_build_system
  smf_is_using_old_build_system ? "" : "-UseNewBuildSystem=YES CODE_SIGN_STYLE=Manual"
end

def smf_is_using_old_build_system
  project_root = smf_workspace_dir

  return false if project_root.nil?

  case @platform
  when :flutter
    project_root = project_root + "/ios"
  else
    project_root = project_root
  end

  workspace_file = `cd #{project_root} && ls | grep -E "(.|\s)+\.xcworkspace"`.gsub("\n", "")

  if (workspace_file == "" || workspace_file == nil)
    return false
  end

  file_to_search = File.join(project_root, "#{workspace_file}/xcshareddata/WorkspaceSettings.xcsettings")

  return false if (File.exist?(file_to_search) == false)

  file_to_search_opened = File.open(file_to_search, "r")
  contents = file_to_search_opened.read

  regex = /<key>BuildSystemType<\/key>\n\t<string>Original<\/string>/

  return true if (contents.match(regex) != nil)

end
