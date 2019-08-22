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

    should_clean_project = build_variant_config[:should_clean_project] if get_should_clean_project != nil

    unlock_keychain(path: "jenkins.keychain", password: ENV[$KEYCHAIN_JENKINS_ENV_KEY]) if smf_is_keychain_enabled

    smf_setup_correct_xcode_executable_for_build

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


