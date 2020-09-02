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

  gym(
      clean: clean_project,
      workspace: !workspace.nil? ? workspace : "#{project_name}.xcworkspace",
      scheme: scheme,
      configuration: xcconfig_name,
      codesigning_identity: code_signing_identity,
      output_directory: 'build',
      xcargs: smf_xcargs_for_build_system,
      archive_path: "build/",
      derived_data_path: "build/derivedData/",
      output_name: output_name,
      include_symbols: true,
      include_bitcode: (upload_itc && upload_bitcode),
      export_options: { iCloudContainerEnvironment: icloud_environment },
      export_method: export_method,
      skip_package_ipa: skip_package_ipa,
      skip_package_pkg: skip_package_pkg,
      xcpretty_formatter: _smf_get_xcpretty_formatter_path,
      catalyst_platform: catalyst_platform
  )
end

def smf_xcargs_for_build_system
  smf_is_using_old_build_system ? "" : "-UseNewBuildSystem=YES"
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

  regex = /<dict>\n\t<key>BuildSystemType<\/key>\n\t<string>Original<\/string>\n<\/dict>/

  return true if (contents.match(regex) != nil)

end

def _smf_get_xcpretty_formatter_path
  # Because currently bundler is printing a lot of gem warnings, we have to take the last line of the output which actually is the correct path we want
  path = sh('xcpretty-json-formatter').split("\n").last

  if path.nil?
    UI.message('Error getting path to xcpretty-json-formatter. Seems like the Gem (https://github.com/marcelofabri/xcpretty-json-formatter) is not (corrrectly) installed!')
    raise 'Error getting path to xcpretty-json-formatter'
  else
    UI.message("Found path to xcpretty-formatter: #{path}")
  end

  path
end

