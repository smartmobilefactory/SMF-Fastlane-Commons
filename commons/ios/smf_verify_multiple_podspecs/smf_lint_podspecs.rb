private_lane :smf_lint_podspecs do |options|

  podspec = options[:main_podspec]
  additional_podspecs = options[:additional_podspecs]
  required_xcode_version = options[:required_xcode_version]

  next if additional_podspecs.nil? || additional_podspecs.count < 1

  smf_setup_correct_xcode_executable_for_build(required_xcode_version: required_xcode_version)

  UI.message("Linting podspec: #{podspec}")

  pod_lib_lint(
    allow_warnings: true,
    sources: $PODSPEC_REPO_SOURCES,
    podspec: podspec,
    fail_fast: true
  )

  additional_podspecs.each do |podspec_path|

    UI.message("Linting podspec: #{podspec_path}")

    pod_lib_lint(
      allow_warnings: true,
      sources: $PODSPEC_REPO_SOURCES,
      podspec: podspec_path,
      include_podspecs: podspec,
      fail_fast: true
    )
  end
end