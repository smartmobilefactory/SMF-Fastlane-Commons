private_lane :smf_lint_podspecs do |options|

  required_xcode_version = options[:required_xcode_version]

  smf_setup_correct_xcode_executable_for_build(required_xcode_version: required_xcode_version)

  UI.message("Linting all podspecs")

  pod_lib_lint(
    allow_warnings: true,
    sources: $PODSPEC_REPO_SOURCES,
    podspec: '*.podspec',
    include_podspecs: '*.podspec',
    fail_fast: true
  )
end