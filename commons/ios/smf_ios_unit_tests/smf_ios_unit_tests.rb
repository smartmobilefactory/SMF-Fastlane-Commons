private_lane :smf_ios_unit_tests do |options|

  project_name = options[:project_name]
  unit_test_scheme = options[:unit_test_scheme]
  scheme = options[:scheme]
  unit_test_xcconfig_name = options[:unit_test_xcconfig_name]
  device = options[:device]
  required_xcode_version = options[:required_xcode_version]
  runner_xcode_version = options[:unit_test_runner_xcode_version]
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

    # The scheme, not the device, used to be printed here — in the one line a reader consults to
    # find out which simulator a run used (RWCIT-2118).
    if device.nil?
      UI.important("No simulator configured — scan falls back to the node's default.")
    else
      UI.important("Simulator to run the tests on: \"#{device}\"")
    end

    destination = testing_for_mac ? "platform=macOS,arch=x86_64" : nil

    # RWCIT-2098: a sanitizer report makes xcodebuild treat the test process as hung, so it
    # starts `simctl diagnose --timeout=600` and the build stands still for ten minutes before
    # the request gives up and the run continues green. Measured on CorporateBenefits-MP: 611 s
    # with the sanitizer, 35 s without it, 27 s with it and this flag. The step only gathers a
    # sysdiagnose for post-mortem use — the sanitizer's own findings stay in the test log, where
    # smf_danger reads them. Left at the default without a sanitizer, so a genuine test failure
    # still produces diagnostics.
    diagnostics_xcarg = use_thread_sanitizer ? " -collect-test-diagnostics never" : ""

    test_xcargs = "#{smf_xcargs_for_build_system}#{diagnostics_xcarg}"
    scan_options = {
        workspace: "#{project_name}.xcworkspace",
        scheme: scheme_to_use,
        xcargs: test_xcargs,
        cloned_source_packages_path: smf_source_packages_path(test_xcargs),
        clean: false,
        device: device,
        # Without this, scan logs "couldn't find matching simulator", falls back to whatever
        # the node offers and the run stays green — a pin on a model Apple has since retired
        # would quietly stop meaning anything. The check only applies when a device is
        # configured at all, so projects that pin none are unaffected (RWCIT-2118).
        ensure_devices_found: true,
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
        # The xcresult is what Allure 3 reads on Jenkins (CBENEFIOS-3144): it carries every
        # Swift Testing argument case as its own test, which the junit report flattens. No
        # `result_bundle_path`: scan only removes a bundle left by an earlier xcodebuild at its own
        # path, `<output_directory>/<scheme>.xcresult`, and a custom path is handed to xcodebuild
        # as it is — the build-for-testing step of the split run (RWCIT-2119) then leaves a bundle
        # behind and the test run aborts with "Existing file at -resultBundlePath".
        result_bundle: true,
        buildlog_path: $IOS_UNIT_TESTS_BUILD_LOGS_DIRECTORY,
        number_of_retries: 1,
        thread_sanitizer: use_thread_sanitizer
    }

    # A bundle left at scan's own path (`<output_directory>/<scheme>.xcresult`) is removed by scan
    # itself before every run, so nothing has to be deleted here. #319 did this with a constant #318
    # had removed, which made the lane raise before a test started (PR-1315 build 2).

    if _smf_split_unit_test_run?(required_xcode_version, runner_xcode_version)
      _smf_build_and_run_unit_tests_separately(scan_options, required_xcode_version, runner_xcode_version)
    else
      scan(scan_options)
    end
  end

end

# Whether the tests are built and run by two different Xcode versions (RWCIT-2119).
def _smf_split_unit_test_run?(required_xcode_version, runner_xcode_version)
  required = required_xcode_version.to_s.strip
  !required.empty? && _smf_unit_test_runner_xcode_version(runner_xcode_version) != required
end

# The Xcode that runs the tests. Without `unit_test_runner_xcode_version` it is the node's default
# Xcode (RWCIT-2122): every CI Mac runs macOS 27, where the Xcode 26 simulator no longer starts, so
# a project that pins its build to Xcode 26 would hang in every unit test run otherwise. A version
# still pins the runner, and a project without `xcode_version` builds and tests with the default.
def _smf_unit_test_runner_xcode_version(runner_xcode_version)
  runner = runner_xcode_version.to_s.strip
  runner.empty? ? $UNIT_TEST_RUNNER_DEFAULT_XCODE : runner
end

# Builds the tests with the project's Xcode and runs them with a newer one (RWCIT-2119).
#
# On macOS 27.2, AMFI refuses Xcode 26's DTServiceHub: xcodebuild logs "DTServiceHubClient
# failed to bless service hub" and the test runner hangs until "The test runner hung before
# establishing connection". Building and archiving are unaffected. A project that must keep
# building with Xcode 26 therefore builds the app and its tests with it — same SDK, same
# binaries — and leaves only the run to an Xcode that the host macOS still accepts.
#
# Measured on CorporateBenefits-MP (cibre-mini, macOS 27.2): run with Xcode 27.2 → 335 tests in
# 18 s; run with Xcode 26.6 → hung, aborted after 937 s.
def _smf_build_and_run_unit_tests_separately(scan_options, required_xcode_version, runner_xcode_version)
  runner_xcode_version = _smf_unit_test_runner_xcode_version(runner_xcode_version)
  use_default_runner = runner_xcode_version == $UNIT_TEST_RUNNER_DEFAULT_XCODE
  # An empty version selects /Applications/Xcode.app and skips ensure_xcode_version.
  runner_setup_version = use_default_runner ? nil : runner_xcode_version
  runner_label = use_default_runner ? "#{$XCODE_DEFAULT_EXECUTABLE_PATH} (#{_smf_xcode_bundle_version($XCODE_DEFAULT_EXECUTABLE_PATH)})" : "Xcode #{runner_xcode_version}"

  UI.important("Building the unit tests with Xcode #{required_xcode_version}, running them with #{runner_label}.")

  # The simulator is reset once, right before the run. The build log goes to a subfolder: Danger
  # reads the first log in the logs folder for thread sanitizer findings, and those come from the run.
  # Only the run writes the result bundle: the build step would create it at the same path, and the
  # run then stops with "Existing file at -resultBundlePath" (CBENEFIOS-3144).
  scan(scan_options.merge(
    build_for_testing: true,
    skip_build: false,
    reset_simulator: false,
    number_of_retries: 0,
    result_bundle: false,
    result_bundle_path: nil,
    buildlog_path: File.join($IOS_UNIT_TESTS_BUILD_LOGS_DIRECTORY, 'build-for-testing')
  ))

  smf_setup_correct_xcode_executable_for_build(required_xcode_version: runner_setup_version)
  begin
    scan(scan_options.merge(test_without_building: true, skip_build: false))
  ensure
    # Later steps of the same run build or archive again and must use the project's Xcode.
    smf_setup_correct_xcode_executable_for_build(required_xcode_version: required_xcode_version)
  end
end

# The marketing version of an Xcode bundle, for the log only.
def _smf_xcode_bundle_version(xcode_path)
  version = `/usr/bin/defaults read "#{xcode_path}/Contents/Info" CFBundleShortVersionString 2>/dev/null`.strip
  version.empty? ? "unknown version" : version
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

  patterns = [
    "**/#{project_name}.xcodeproj/xcshareddata/xcschemes/#{scheme}.xcscheme",
    "**/#{project_name}.xcworkspace/xcshareddata/xcschemes/#{scheme}.xcscheme",
    "**/xcshareddata/xcschemes/#{scheme}.xcscheme"
  ]

  # Lane code runs with the fastlane folder as working directory, while the
  # project sits next to it. Search from the project root first, so the scheme
  # is found when the fastlane folder lives inside the iOS project directory.
  search_roots = [Dir.pwd]
  fastlane_folder = FastlaneCore::FastlaneFolder.path
  search_roots.unshift(File.expand_path('..', fastlane_folder)) unless fastlane_folder.nil?

  scheme_files = search_roots.uniq.flat_map do |root|
    Dir.glob(patterns, base: root).map { |path| File.join(root, path) }
  end

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

  # A scheme driven by a test plan lists its tests in the plan and carries no
  # TestableReference at all, so counting testables alone reads it as empty and
  # skips the stage — green, with nothing run. A plan reference has no `skipped`
  # attribute; the plan itself decides what is selected (RWCIT-2117).
  test_plans = test_action.scan(/<TestPlanReference\b/).count

  if active.empty? && test_plans.zero?
    UI.important("Scheme \"#{scheme}\" has no active test target — skipping the unit tests.")
    return false
  end

  found = []
  found << "#{active.count} test target(s)" unless active.empty?
  found << "#{test_plans} test plan(s)" unless test_plans.zero?
  UI.important("Scheme \"#{scheme}\" has #{found.join(' and ')} — running the unit tests.")
  true
rescue => exception
  UI.important("Could not inspect the scheme (#{exception}). Assuming it has tests and running them.")
  true
end