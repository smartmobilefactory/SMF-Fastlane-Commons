#############################################
### smf_archive_ipa_if_scheme_is_provided ###
#############################################

desc "Archives the IPA if the build variant declared a scheme"
private_lane :smf_archive_ipa_if_scheme_is_provided do |options|

  # Parameter
  skip_export = (options[:skip_export].nil? ? false : options[:skip_export])
  bulk_deploy_params = options[:bulk_deploy_params]

  if @smf_fastlane_config[:build_variants][@smf_build_variant_sym][:scheme]

    smf_download_provisioning_profiles(
        team_id: get_team_id,
        apple_id: get_apple_id,
        use_wildcard_signing: get_use_wildcard_signing,
        bundle_identifier: get_bundle_identifier,
        use_default_match_config: match_config.nil?,
        match_read_only: get_match_config_read_only,
        match_type: get_match_config_type,
        extensions_suffixes: get_extension_suffixes
    )

    smf_build_app(
      skip_export: skip_export,
      bulk_deploy_params: bulk_deploy_params,
      scheme: get_build_scheme,
      should_clean_project: get_should_clean_project,
      required_xcode_version: get_required_xcode_version,
      project_name: get_project_name,
      xcconfig_name: get_xcconfig_name,
      code_signing_identity: get_code_signing_identity,
      upload_itc: get_upload_itc,
      upload_bitcode: get_upload_bitcode,
      export_method: get_export_method
    )

    if get_use_sparkle == true
      smf_create_dmg_from_app(
          team_id: get_team_id,
          build_scheme: get_build_scheme
      )
    end

  else
    UI.important("The IPA won't be archived as the build variant doesn't contain a scheme")
  end
end

###############################
### smf_build_simulator_app ###
###############################

desc "Creates a Release build for simulators"
private_lane :smf_build_simulator_app do |options|

  # Variables
  project_name = @smf_fastlane_config[:project][:project_name]
  build_variant_config = @smf_fastlane_config[:build_variants][@smf_build_variant_sym]
  build_type = "Release"
  workspace = smf_workspace_dir

  derived_data_path = "#{workspace}/simulator-build/derivedData"
  output_directory_path = "#{derived_data_path}/Build/Products/#{build_type}-iphonesimulator"
  output_filename = "#{build_variant_config[:scheme]}.app"

  sh "cd #{workspace}; xcodebuild -workspace #{project_name}.xcworkspace -scheme #{build_variant_config[:scheme]} -configuration #{build_type} -arch x86_64 ONLY_ACTIVE_ARCH=NO -sdk iphonesimulator -derivedDataPath #{derived_data_path}"

  # Compress the .app and copy it to the general build folder
  sh "cd \"#{output_directory_path}\"; zip -r \"#{output_filename}.zip\" \"#{output_filename}\"/*"
  sh "cp \"#{output_directory_path}/#{output_filename}.zip\" #{workspace}/build/SimulatorBuild#{build_type}.zip"

end



##############################
### smf_perform_unit_tests ###
##############################

desc "Performs the unit tests of a project."
private_lane :smf_perform_unit_tests do |options|

  should_perform_tests = @smf_fastlane_config[:build_variants][@smf_build_variant_sym]["pr.perform_unit_tests".to_sym]

  if (should_perform_tests == false)
    UI.message("Build Variant \"#{@smf_build_variant}\" is not allowed to perform Unit Tests")
    return
  end

  # Variables
  project_name = @smf_fastlane_config[:project][:project_name]
  build_variant_config = @smf_fastlane_config[:build_variants][@smf_build_variant_sym]
  device = build_variant_config["tests.device_to_test_against".to_sym]
  use_xcconfig = build_variant_config[:xcconfig_name].nil? ? false : true
  xcconfig_name = use_xcconfig ? build_variant_config[:xcconfig_name][:unittests] : nil

  # Prefer the unit test scheme over the normal scheme
  scheme = (build_variant_config[:unit_test_scheme].nil? ? build_variant_config[:scheme] : build_variant_config[:unit_test_scheme])

  UI.important("Performing the unit tests with the scheme \"#{scheme}\"")

  destination = (ENV[$FASTLANE_PLATFORM_NAME_ENV_KEY] == "mac" ? "platform=macOS,arch=x86_64" : nil)

  UI.message("Use destination \"#{destination}\" for platform \"#{ENV[$FASTLANE_PLATFORM_NAME_ENV_KEY]}\"")

  scan(
    workspace: "#{project_name}.xcworkspace",
    scheme: scheme,
    xcargs: smf_xcargs_for_build_system,
    clean: false,
    device: device,
    destination: destination,
    configuration: xcconfig_name,
    code_coverage: true,
    output_types: "html,junit,json-compilation-database",
    output_files: "report.html,report.junit,report.json"
    )

  ENV[$SMF_DID_RUN_UNIT_TESTS_ENV_KEY] = "true"

end

##############
### HELPER ###
##############

def smf_can_unit_tests_be_performed

  # Variables
  project_name = @smf_fastlane_config[:project][:project_name]
  build_variant_config = @smf_fastlane_config[:build_variants][@smf_build_variant_sym]

  # Prefer the unit test scheme over the normal scheme
  scheme = (build_variant_config[:unit_test_scheme].nil? ? build_variant_config[:scheme] : build_variant_config[:unit_test_scheme])

  use_xcconfig = build_variant_config[:xcconfig_name].nil? ? false : true
  xcconfig_name = use_xcconfig ? build_variant_config[:xcconfig_name][:unittests] : nil

  UI.important("Checking whether the unit tests with the scheme \"#{scheme}\" can be performed.")

  destination = (ENV[$FASTLANE_PLATFORM_NAME_ENV_KEY] == "mac" ? "platform=macOS,arch=x86_64" : nil)

  UI.message("Use destination \"#{destination}\" for platform \"#{ENV[$FASTLANE_PLATFORM_NAME_ENV_KEY]}\"")

  begin
    scan(
      workspace: "#{project_name}.xcworkspace",
      scheme: scheme,
      destination: destination,
      configuration: xcconfig_name,
      clean: false,
      skip_build: true,
      xcargs: "-dry-run #{smf_xcargs_for_build_system}"
    )

    UI.important("Unit tests can be performed")
    
    return true
  rescue => exception
    
    UI.important("Unit tests can't be performed: #{exception}")
    
    return false
  end

end

def smf_is_build_variant_internal
  return (@smf_build_variant.include? "alpha") || smf_is_build_variant_a_pod
end

def smf_increment_build_number_prefix_string
  return "Increment build number to "
end

def smf_is_bitcode_enabled
  # Variables
  project_name = @smf_fastlane_config[:project][:project_name]
  scheme = @smf_fastlane_config[:build_variants][@smf_build_variant_sym][:scheme]

  enable_bitcode_string = sh "cd .. && xcrun xcodebuild -showBuildSettings -workspace\ \"#{project_name}.xcworkspace\" -scheme \"#{scheme}\" \| grep \"ENABLE_BITCODE = \" \| grep -o \"\\(YES\\|NO\\)\""
  return ((enable_bitcode_string.include? "NO") == false)
end

def smf_is_build_variant_a_pod
  is_pod = (@smf_fastlane_config[:build_variants][@smf_build_variant_sym][:podspec_path] != nil)

  UI.message("Build variant is a pod: #{is_pod}, as the config is #{@smf_fastlane_config[:build_variants][@smf_build_variant_sym]}")

  return is_pod
end

def smf_is_build_variant_a_decoupled_ui_test
  is_ui_test = (@smf_fastlane_config[:build_variants][@smf_build_variant_sym][:"ui_test.target.bundle_identifier".to_sym] != nil)

  UI.message("Build variant is a is_ui_test: #{is_ui_test}, as the config is #{@smf_fastlane_config[:build_variants][@smf_build_variant_sym]}")

  return is_ui_test
end
