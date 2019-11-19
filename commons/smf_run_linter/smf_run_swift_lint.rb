# Constants
SWIFT_LINT_OUTPUT_PATH = 'build/swiftlint.result.json'

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
end

def smf_swift_lint_output_path
  "#{smf_workspace_dir}/#{SWIFT_LINT_OUTPUT_PATH}"
end