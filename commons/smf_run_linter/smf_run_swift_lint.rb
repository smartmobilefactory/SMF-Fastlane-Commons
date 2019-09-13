# Constants
SWIFT_LINT_OUTPUT_PATH = 'build/swiftlint.result.json'

private_lane :smf_run_swift_lint do
  swiftlint(
      output_file: smf_swift_lint_ouput_path,
      config_file: "#{@fastlane_commons_dir_path}/commons/smf_run_linter/swiftlint.yml",
      ignore_exit_status: true,
      reporter: "checkstyle"
  )
end

def smf_swift_lint_ouput_path
  "#{smf_workspace_dir}/#{SWIFT_LINT_OUTPUT_PATH}"
end