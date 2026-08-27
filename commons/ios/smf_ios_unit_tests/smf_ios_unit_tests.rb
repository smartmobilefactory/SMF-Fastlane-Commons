private_lane :smf_ios_unit_tests do |options|

  project_name = options[:project_name]
  unit_test_scheme = options[:unit_test_scheme]
  scheme = options[:scheme]
  unit_test_xcconfig_name = options[:unit_test_xcconfig_name]
  device = options[:device]
  required_xcode_version = options[:required_xcode_version]
  testing_for_mac = options[:testing_for_mac]
  use_thread_sanitizer = !options[:use_thread_sanitizer].nil? ? options[:use_thread_sanitizer] : true

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
        skip_build: true,
        derived_data_path: $IOS_DERIVED_DATA_PATH,
        output_directory: $IOS_BUILD_OUTPUT_DIR,
        output_types: "html,junit,json-compilation-database",
        output_files: "report.html,report.junit,report.json",
        buildlog_path: $IOS_UNIT_TESTS_BUILD_LOGS_DIRECTORY,
        number_of_retries: 1,
        thread_sanitizer: use_thread_sanitizer
    )
  end

end

# Whether the scheme has anything to test.
#
# This used to run `scan` with `xcargs: "-dry-run …"`. Xcode removed support for
# `-dry-run`, so that call could only ever raise — the rescue then reported
# "Maybe the project does not have any unit tests?" and returned false, and the
# real test run was skipped. Builds stayed green while no test was executed.
#
# The replacement reads the scheme's TestAction instead of starting Xcode: it is
# instant, and it cannot fail for reasons unrelated to the question.
#
# It deliberately defaults to TRUE whenever the scheme cannot be located or
# parsed. Running the tests and failing loudly is recoverable; skipping them
# silently is what caused this bug in the first place.
def _smf_can_unit_tests_be_preformed(project_name, scheme, unit_test_xcconfig_name = nil, testing_for_mac = nil)

  UI.important("Checking whether the scheme \"#{scheme}\" has a test target.")

  scheme_files = Dir.glob([
    "**/#{project_name}.xcodeproj/xcshareddata/xcschemes/#{scheme}.xcscheme",
    "**/#{project_name}.xcworkspace/xcshareddata/xcschemes/#{scheme}.xcscheme",
    "**/xcshareddata/xcschemes/#{scheme}.xcscheme"
  ])

  if scheme_files.empty?
    UI.important("Scheme file for \"#{scheme}\" not found — assuming it has tests and running them.")
    return true
  end

  content = File.read(scheme_files.first)
  test_action = content[/<TestAction.*?<\/TestAction>/m]

  if test_action.nil?
    UI.important("Scheme \"#{scheme}\" has no TestAction — skipping the unit tests.")
    return false
  end

  # A testable counts only when it is not skipped.
  testables = test_action.scan(/<TestableReference(.*?)<\/TestableReference>/m).flatten
  active = testables.reject { |t| t =~ /skipped\s*=\s*"YES"/i }

  if active.empty?
    UI.important("Scheme \"#{scheme}\" has no active test target — skipping the unit tests.")
    return false
  end

  UI.important("Scheme \"#{scheme}\" has #{active.count} test target(s) — running the unit tests.")
  true
rescue => exception
  UI.important("Could not inspect the scheme (#{exception}). Assuming it has tests and running them.")
  true
end