# ==========================================
# Modern SwiftLint Integration (CBENEFIOS-2070)
# ==========================================
# SwiftLint now runs via SPM Build Tool Plugin in projects.
# Projects handle SwiftLint configuration and execution themselves.
# This lane is kept for backward compatibility but does nothing.
# ==========================================

private_lane :smf_run_swift_lint do |options|
  UI.message("ℹ️  SwiftLint runs via SPM Build Tool Plugin in each project")
  UI.message("Projects should have:")
  UI.message("  1. SwiftLintPlugins added as SPM dependency")
  UI.message("  2. Build Tool Plugin enabled in Xcode targets")
  UI.message("  3. .swiftlint.yml configuration committed")
  UI.message("")
  UI.message("For PR checks, danger-swiftlint will run SwiftLint directly")
  UI.message("No separate CLI execution needed from Fastlane")
end

# ==========================================
# Deprecated/Removed Functions (CBENEFIOS-2070)
# ==========================================
# These functions are kept as stubs for backward compatibility
# but return nil/0 since SwiftLint runs via SPM Build Tool Plugin
# ==========================================

# Deprecated: Returns 0 (no warnings tracked via this method anymore)
def smf_swift_lint_number_of_warnings
  UI.important("⚠️  smf_swift_lint_number_of_warnings is deprecated")
  UI.important("SwiftLint now runs via SPM Build Tool Plugin")
  UI.important("Violations appear directly in Xcode and PR comments via danger-swiftlint")
  return 0
end

# Deprecated: Returns path that won't exist (SwiftLint runs via SPM Build Tool Plugin)
def smf_swift_lint_output_xml_path
  return File.join(smf_workspace_dir, "build", "swiftlint_output.xml")
end

# Deprecated: Returns path that won't exist (SwiftLint runs via SPM Build Tool Plugin)
def smf_swift_lint_analyze_xml_path
  return File.join(smf_workspace_dir, "build", "swiftlint_analyze.xml")
end

# Deprecated: Returns path that won't exist (SwiftLint runs via SPM Build Tool Plugin)
def smf_swift_lint_rules_report_path
  return File.join(smf_workspace_dir, "build", "swiftlint_rules_report.txt")
end
