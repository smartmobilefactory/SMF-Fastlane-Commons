# Constants
SWIFT_LINT_OUTPUT_PATH = 'build/swiftlint.result.json'
SWIFT_LINT_RULES_REPORT_DIR_PATH = 'build/'

private_lane :smf_run_swift_lint do

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
      ignore_exit_status: true,
      reporter: "checkstyle",
      executable: swift_lint_executable_path
  )

  # Generate Rules Report
  UI.important("Generating report of unused Swiftlint rules")
  swift_lint_report = "#{smf_workspace_dir}/Submodules/SMF-iOS-CommonProjectSetupFiles/SwiftLint/check_missing_rule_configurations.sh"
  swift_lint_config = "#{smf_workspace_dir}"
  swift_lint_output = "#{smf_workspace_dir}/#{SWIFT_LINT_RULES_REPORT_DIR_PATH}"

  # Dir.chdir(smf_workspace_dir) do
  sh("#{swift_lint_report} #{swift_lint_config} #{swift_lint_output}")
  # end
end

def smf_swift_lint_output_path
  "#{smf_workspace_dir}/#{SWIFT_LINT_OUTPUT_PATH}"
end

def smf_swift_lint_rules_report_path
  "#{smf_workspace_dir}/#{SWIFT_LINT_RULES_REPORT_PATH}"
end