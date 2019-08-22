private_lane :smf_build_app do |options|

  case @platform
  when :ios

    UI.important("Creating the Xcode archive")

    # Parameter
    skip_package_ipa = (options[:skip_export].nil? ? false : options[:skip_export])
    bulk_deploy_params = options[:bulk_deploy_params]

    # Variables
    scheme = get_build_scheme
    output_name = scheme

    # Check if the project defined if the build should be cleaned. Other wise the default behavior is used based on the whether the archiving is a bulk operation.
    should_clean_project = bulk_deploy_params != nil ? (bulk_deploy_params[:index] == 0 && bulk_deploy_params[:count] > 1) : true
    if build_variant_config[:should_clean_project] != nil
      should_clean_project = build_variant_config[:should_clean_project]
    end

    if smf_is_keychain_enabled
      unlock_keychain(path: "jenkins.keychain", password: ENV[$KEYCHAIN_JENKINS_ENV_KEY])
    end

    # Make sure that the correct xcode version is selected when building the app
    required_xcode_version = get_required_xcode_version
    xcode_executable_path = "#{$XCODE_EXECUTABLE_PATH_PREFIX}" + required_xcode_version + "#{$XCODE_EXECUTABLE_PATH_POSTFIX}"

    ENV[$DEVELOPMENT_DIRECTORY_KEY] = xcode_executable_path

    xcode_select(xcode_executable_path)
    ensure_xcode_version(version: required_xcode_version)

    gym(
        clean: should_clean_project,
        workspace: "#{get_project_name}.xcworkspace",
        scheme: scheme,
        configuration: get_xcconfig_name,
        codesigning_identity: get_code_signing_identity,
        output_directory: "build",
        xcargs: smf_xcargs_for_build_system,
        archive_path:"build/",
        output_name: output_name,
        include_symbols: true,
        include_bitcode: (get_upload_itc && get_upload_bitcode),
        export_method: get_export_method,
        export_options: { iCloudContainerEnvironment: get_icloud_environment },
        skip_package_ipa: skip_package_ipa,
        xcpretty_formatter: "/Library/Ruby/Gems/2.3.0/gems/xcpretty-json-formatter-0.1.0/lib/json_formatter.rb"
    )

  when :android
  end
end


