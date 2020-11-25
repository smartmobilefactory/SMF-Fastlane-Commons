private_lane :smf_lint_podspecs do |options|

  podspecs = options[:podspecs]
  required_xcode_version = options[:required_xcode_version]

  next if podspecs.nil? || podspecs.count < 2

  smf_setup_correct_xcode_executable_for_build(required_xcode_version: required_xcode_version)

  podspecs.each do |podspec_path|

    UI.message("Linting podspec: #{podspec_path}")

    pod_lib_lint(
      allow_warnings: true,
      sources: $PODSPEC_REPO_SOURCES,
      podspec: podspec_path,
      include_podspecs: podspecs,
      fail_fast: true
    )
  end
end