private_lane :smf_ios_unit_tests do |options|

  project_name = options[:project_name]
  unit_test_scheme = options[:unit_test_scheme]
  scheme = options[:scheme]
  unit_test_xcconfig_name = options[:unit_test_xcconfig_name]
  device = options[:device]
  required_xcode_version = options[:required_xcode_version]
  testing_for_mac = options[:testing_for_mac]

  scheme_to_use = unit_test_scheme.nil? ? scheme : unit_test_scheme

  smf_setup_correct_xcode_executable_for_build(required_xcode_version: required_xcode_version)

  can_preform_unit_tests = _smf_can_unit_tests_be_preformed(
                             project_name,
                             scheme_to_use,
                             unit_test_xcconfig_name,
                             testing_for_mac
                          )

  if can_preform_unit_tests == true

    UI.important("Performing the unit tests with the scheme \"#{scheme_to_use}\"")
    UI.important("Name of the simulator type to run tests on: \"#{scheme_to_use}\"")

    destination = testing_for_mac ? "platform=macOS,arch=x86_64" : nil

    scan(
        workspace: "#{project_name}.xcworkspace",
        scheme: scheme_to_use,
        xcargs: smf_xcargs_for_build_system,
        clean: false,
        device: device,
        destination: destination,
        configuration: unit_test_xcconfig_name,
        disable_concurrent_testing: true,
        reset_simulator: true,
        code_coverage: true,
        derived_data_path: $IOS_DERIVED_DATA_PATH,
        output_directory: 'build',
        output_types: "html,junit,json-compilation-database",
        output_files: "report.html,report.junit,report.json",
        buildlog_path: $IOS_UNIT_TESTS_BUILD_LOGS_DIRECTORY,
        result_bundle: true,
        number_of_retries: 1,
    )
  end

end

def _smf_can_unit_tests_be_preformed(project_name, scheme, unit_test_xcconfig_name, testing_for_mac = nil)

  UI.important("Checking whether the unit tests with the scheme \"#{scheme}\" can be performed.")

  destination = testing_for_mac ? "platform=macOS,arch=x86_64" : nil

  begin
    scan(
        workspace: "#{project_name}.xcworkspace",
        scheme: scheme,
        configuration: unit_test_xcconfig_name,
        destination: destination,
        clean: false,
        skip_build: true,
        xcargs: "-dry-run #{smf_xcargs_for_build_system}"
    )

    UI.important("Unit tests can be performed")

    return true
  rescue => exception

    UI.important("Unit tests can't be performed: #{exception}. Maybe the project does not have any unit tests?")

    return false
  end
end