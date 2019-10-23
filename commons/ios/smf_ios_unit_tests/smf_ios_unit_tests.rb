private_lane :smf_ios_unit_tests do |options|

  project_name = options[:project_name]
  unit_test_scheme = options[:unit_test_scheme]
  scheme = options[:scheme]
  unit_test_xcconfig_name = options[:unit_test_xcconfig_name]
  device = options[:device]
  required_xcode_version = options[:required_xcode_version]
  unit_testing_for_mac_os = options[:unit_testing_for_mac_os]

  scheme_to_use = unit_test_scheme.nil? ? scheme : unit_test_scheme

  smf_setup_correct_xcode_executable_for_build(required_xcode_version: required_xcode_version)

  can_preform_unit_tests = _smf_can_unit_tests_be_preformed(
                               project_name,
                               scheme_to_use,
                               unit_test_xcconfig_name,
                               unit_testing_for_mac_os
                          )

  if can_preform_unit_tests == true

    UI.important("Performing the unit tests with the scheme \"#{scheme_to_use}\"")

    destination = unit_testing_for_mac_os ? "platform=macOS,arch=x86_64" : nil

    scan(
        workspace: "#{project_name}.xcworkspace",
        scheme: scheme_to_use,
        xcargs: smf_xcargs_for_build_system,
        clean: false,
        device: device,
        destination: destination,
        configuration: unit_test_xcconfig_name,
        code_coverage: true,
        output_directory: 'build',
        output_types: "html,junit,json-compilation-database",
        output_files: "report.html,report.junit,report.json"
    )
  end

end

def _smf_can_unit_tests_be_preformed(project_name, scheme, unit_test_xcconfig_name, unit_testing_for_mac_os = nil)

  UI.important("Checking whether the unit tests with the scheme \"#{scheme}\" can be performed.")

  destination = unit_testing_for_mac_os ? "platform=macOS,arch=x86_64" : nil

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