require 'fileutils'

# Constants
SWIFT_LINT_OUTPUT_BASE_DIR = 'build/'
SWIFT_LINT_OUTPUT_PATH = 'build/swiftlint.result.json'
SWIFT_LINT_RULES_REPORT_PATH = 'build/swiftlint-rules-report.txt'

private_lane :smf_run_swift_lint do
  _create_output_base_folder()

  swift_lint_executable_path = "#{smf_workspace_dir}/Submodules/SMF-iOS-CommonProjectSetupFiles/SwiftLint/portable_swiftlint/swiftlint"
  swift_lint_yml = "#{smf_workspace_dir}/.swiftlint.yml"

  if !File.exist?(swift_lint_executable_path)
    UI.important("SwiftLint executable not present at #{swift_lint_executable_path}. Skipping SwiftLint.")
    next
  end

  if !File.exist?(swift_lint_yml)
    UI.important("SwiftLint .yml not present at #{swift_lint_yml}. Skipping SwiftLint.")
    next
  end

  swiftlint(
      output_file: smf_swift_lint_output_path,
      config_file: swift_lint_yml,
      reporter: "json",
      ignore_exit_status: true,
      executable: swift_lint_executable_path
  )

  # Generate Rules Report
  UI.important("Generating report of unused Swiftlint rules")
  swift_lint_report = "#{smf_workspace_dir}/Submodules/SMF-iOS-CommonProjectSetupFiles/SwiftLint/check_missing_rule_configurations.sh"
  if File.exist?(swift_lint_report)
    sh("#{swift_lint_report} #{smf_workspace_dir} #{smf_workspace_dir}/#{SWIFT_LINT_RULES_REPORT_PATH}")
  end
end

def _create_output_base_folder
  dirname = File.dirname("#{smf_workspace_dir}/#{SWIFT_LINT_OUTPUT_BASE_DIR}")
  # create dir only if not existing
  unless File.directory?(dirname)
    FileUtils.mkdir_p(dirname)
  end
end

def smf_swift_lint_output_path
  "#{smf_workspace_dir}/#{SWIFT_LINT_OUTPUT_PATH}"
end

def smf_swift_lint_rules_report_path
  "#{smf_workspace_dir}/#{SWIFT_LINT_RULES_REPORT_PATH}"
end
