require 'fileutils'

# Constants
SWIFT_LINT_OUTPUT_BASE_DIR = 'build/'
SWIFT_LINT_OUTPUT_XML_PATH = 'build/swiftlint.result.xml'
SWIFT_LINT_ANALYZE_OUTPUT_XML_PATH = 'build/swiftlint-analyze.result.xml'
SWIFT_LINT_OUTPUT_JSON_PATH = 'build/swiftlint.result.json'
SWIFT_LINT_RULES_REPORT_PATH = 'build/swiftlint-rules-report.txt'

private_lane :smf_run_swift_lint do |options|
  _smf_create_output_base_folder

  required_xcode_version = options[:required_xcode_version]
  if !required_xcode_version.nil?
    smf_setup_correct_xcode_executable_for_build(required_xcode_version: required_xcode_version)
  end

  swift_lint_executable_path = "#{smf_workspace_dir}/Submodules/SMF-iOS-CommonProjectSetupFiles/SwiftLint/portable_swiftlint/swiftlint"
  swift_lint_yml = "#{smf_workspace_dir}/.swiftlint.yml"

  unless File.exist?(swift_lint_executable_path)
    UI.important("SwiftLint executable not present at #{swift_lint_executable_path}. Skipping SwiftLint.")
    next
  end

  unless File.exist?(swift_lint_yml)
    _smf_generate_swiftlint_yml

    unless File.exist?(swift_lint_yml)
      UI.important("SwiftLint .yml not present at #{swift_lint_yml}. Skipping SwiftLint.")
      next
    end
  end

  # Perform a first lint using the 'checkstyle' reporter for the Danger output in the PR
  swiftlint(
      output_file: smf_swift_lint_output_xml_path,
      reporter: 'checkstyle',
      ignore_exit_status: true,
      executable: swift_lint_executable_path
  )

  # Swiftlint Analyze
  compiler_log_path = _smf_get_build_logs_for_analyze
  if compiler_log_path.nil? == false
    swiftlint(
      mode: :analyze, 
      output_file: smf_swift_lint_analyze_xml_path,
      reporter: 'checkstyle',
      ignore_exit_status: true,
      executable: swift_lint_executable_path,
      compiler_log_path: compiler_log_path # compiler_log_path is required for `analyze` 
    )
  else
    UI.important("Skipping SwiftLint analyze: build logs not found.")
  end

  # Perform a seconf lint using the 'json' reporter for the unused rules report
  swiftlint(
      output_file: smf_swift_lint_output_json_path,
      reporter: 'json',
      ignore_exit_status: true,
      executable: swift_lint_executable_path
  )

  # Generate Rules Report
  UI.important('Generating report of unused Swiftlint rules')
  swift_lint_report = "#{smf_workspace_dir}/Submodules/SMF-iOS-CommonProjectSetupFiles/SwiftLint/check_missing_rule_configurations.sh"
  unless File.exist?(swift_lint_report)
    UI.important("SwiftLint rules report not present at #{swift_lint_report}. Skipping SwiftLint Rules Report.")
    next
  end

  sh("#{swift_lint_report} #{smf_workspace_dir} #{smf_workspace_dir}/#{SWIFT_LINT_RULES_REPORT_PATH}")
end

# Returns absolute path to the build logs.
# Will first look for the unit tests build logs (in order to cover also the unit tests class with `analyze`)
# If not found, will default to the archive build logs
def _smf_get_build_logs_for_analyze
  unit_tests_build_logs_directory = File.join(smf_workspace_dir, $IOS_UNIT_TESTS_BUILD_LOGS_DIRECTORY)
  compiler_log_path = Dir["#{unit_tests_build_logs_directory}/*.log"].first

  if compiler_log_path.nil?
    archive_build_logs_directory = File.join(smf_workspace_dir, $IOS_ARCHIVE_BUILD_LOGS_DIRECTORY)
    compiler_log_path = Dir["#{archive_build_logs_directory}/*.log"].first
  end

  return compiler_log_path
end

# Generate the .swiftlint.yml and perform a first lint.
# Parse the xcodeproj to fetch the correct arguments required by the 'copy-and-run-swiftlint-config.sh' script.
def _smf_generate_swiftlint_yml
  pbxproj = smf_pbxproj_file_path
  regex = "shellScript = .*(/Submodules/SMF-iOS-CommonProjectSetupFiles/setup-common-project-files.sh.*)$"
  pbxproj_content = File.read(smf_pbxproj_file_path)

  script_path = "#{smf_workspace_dir}/Submodules/SMF-iOS-CommonProjectSetupFiles/SwiftLint/copy-and-run-swiftlint-config.sh"
  use_framework_config = _smf_swift_lint_is_framework(pbxproj_content)
  use_swiftUI_config = _smf_swift_lint_is_swiftUI_project(pbxproj_content)

  # Use the script to generate the .swiftlint.yml
  # The script will lint the code, though the result is ignored as it does not use the fastlane plugin.
  `#{script_path} #{smf_workspace_dir} #{use_framework_config} #{use_swiftUI_config}`
end

# Based on regex, analyse the pbxproj to determine wheter the current project should use the swiftlint configuration for frameworks
def _smf_swift_lint_is_framework(pbxproj_content)
  base_regex = 'shellScript = .*/Submodules/SMF-iOS-CommonProjectSetupFiles/setup-common-project-files.sh.*'
  regex = "#{base_regex}--targettype.*(com.apple.product-type.framework).*$"
  if matches = pbxproj_content.match(regex)
    if matches.captures.count > 0
      return true
    end
  end
  return false
end

# Based on regex, analyse the pbxproj to determine wheter the current project should use the swiftlint configuration for SwiftUI projects.
def _smf_swift_lint_is_swiftUI_project(pbxproj_content)
  base_regex = 'shellScript = .*/Submodules/SMF-iOS-CommonProjectSetupFiles/setup-common-project-files.sh.*'
  regex = "#{base_regex}(--SwiftUI).*$"
  if matches = pbxproj_content.match(regex)
    if matches.captures.count > 0
      return true
    end
  end
  return false
end

def _smf_create_output_base_folder
  dirname = "#{smf_workspace_dir}/#{SWIFT_LINT_OUTPUT_BASE_DIR}"
  # create dir only if not existing
  unless File.directory?(dirname)
    FileUtils.mkdir_p(dirname)
  end
end

# Path to the `lint` report
def smf_swift_lint_output_xml_path
  "#{smf_workspace_dir}/#{SWIFT_LINT_OUTPUT_XML_PATH}"
end

# Path to the `analyze` report
def smf_swift_lint_analyze_xml_path
  "#{smf_workspace_dir}/#{SWIFT_LINT_ANALYZE_OUTPUT_XML_PATH}"
end

def smf_swift_lint_output_json_path
  "#{smf_workspace_dir}/#{SWIFT_LINT_OUTPUT_JSON_PATH}"
end

def smf_swift_lint_rules_report_path
  "#{smf_workspace_dir}/#{SWIFT_LINT_RULES_REPORT_PATH}"
end

def smf_swift_lint_number_of_warnings
  if File.file?(smf_swift_lint_output_json_path) == false
    raise "Couldn't locate swiftlint report at #{smf_swift_lint_output_json_path}"
  end

  swiftlint_report = File.read(smf_swift_lint_output_json_path)
  swiftlint_json = JSON.parse(swiftlint_report)
  return swiftlint_json.count
end
