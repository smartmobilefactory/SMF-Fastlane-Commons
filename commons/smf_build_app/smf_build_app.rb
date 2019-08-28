private_lane :smf_build_app do |options|

  case @platform
  when :ios

    UI.important("Creating the Xcode archive")

    # Parameter
    skip_package_ipa = (options[:skip_export].nil? ? false : options[:skip_export])
    bulk_deploy_params = options[:bulk_deploy_params]
    scheme = options[:scheme]
    should_clean_project = options[:should_clean_project]
    required_xcode_version = options[:required_xcode_version]
    project_name = options[:project_name]
    xcconfig_name = options[:xcconfig_name]
    code_signing_identity = options[:code_signing_identity]
    upload_itc = options[:upload_itc]
    upload_bitcode = options[:upload_bitcode]
    export_method = options[:export_method]

    output_name = scheme

    # Check if the project defined if the build should be cleaned. Other wise the default behavior is used based on the whether the archiving is a bulk operation.
    clean_project = !bulk_deploy_params.nil? ? (bulk_deploy_params[:index] == 0 && bulk_deploy_params[:count] > 1) : true

    clean_project = should_clean_project if should_clean_project != nil

    unlock_keychain(path: "jenkins.keychain", password: ENV[$KEYCHAIN_JENKINS_ENV_KEY]) if smf_is_keychain_enabled

    smf_setup_correct_xcode_executable_for_build(required_xcode_version: required_xcode_version)

    gym(
        clean: clean_project,
        workspace: "#{project_name}.xcworkspace",
        scheme: scheme,
        configuration: xcconfig_name,
        codesigning_identity: code_signing_identity,
        output_directory: "build",
        xcargs: smf_xcargs_for_build_system,
        archive_path:"build/",
        output_name: output_name,
        include_symbols: true,
        include_bitcode: (upload_itc && upload_bitcode),
        export_method: get_export_method,
        export_options: { iCloudContainerEnvironment: export_method },
        skip_package_ipa: skip_package_ipa,
        xcpretty_formatter: "/Library/Ruby/Gems/2.3.0/gems/xcpretty-json-formatter-0.1.0/lib/json_formatter.rb"
    )

  when :android

    build_variant = options[:build_variant]

    if !build_variant
      UI.important("Building all variants")
      build_variant = ""
    else
      UI.important("Building variant " + build_variant)
    end

    addition = ""
    if ENV[$SMF_KEYSTORE_FILE_KEY]
      KEYSTORE_FILE = ENV[$SMF_KEYSTORE_FILE_KEY]
      KEYSTORE_PASSWORD = ENV[$SMF_KEYSTORE_PASSWORD_KEY]
      KEYSTORE_KEY_ALIAS = ENV[$SMF_KEYSTORE_KEY_ALIAS_KEY]
      KEYSTORE_KEY_PASSWORD = ENV[$SMF_KEYSTORE_KEY_PASSWORD_KEY]
      addition = " -Pandroid.injected.signing.store.file='#{KEYSTORE_FILE}'"
      addition << " -Pandroid.injected.signing.store.password='#{KEYSTORE_PASSWORD}'"
      addition << " -Pandroid.injected.signing.key.alias='#{KEYSTORE_KEY_ALIAS}'"
      addition << " -Pandroid.injected.signing.key.password='#{KEYSTORE_KEY_PASSWORD}'"
    end

    gradle(task: "assemble" + build_variant + addition)

  when :flutter
    UI.message("smf_build_app is not implemented for flutter yet")
  end
end

def smf_xcargs_for_build_system
  smf_is_using_old_build_system ? "" : "-UseNewBuildSystem=YES"
end

def smf_is_using_old_build_system
  project_root = smf_workspace_dir

  return false if project_root.nil?

  workspace_file = `cd #{project_root} && ls | grep -E "(.|\s)+\.xcworkspace"`.gsub("\n", "")

  if (workspace_file == "" || workspace_file == nil)
    return false
  end

  file_to_search = File.join(project_root, "#{workspace_file}/xcshareddata/WorkspaceSettings.xcsettings")

  return false if (File.exist?(file_to_search) == false)

  file_to_search_opened = File.open(file_to_search, "r")
  contents = file_to_search_opened.read

  regex = /<dict>\n\t<key>BuildSystemType<\/key>\n\t<string>Original<\/string>\n<\/dict>/

  return true if (contents.match(regex) != nil)
end

