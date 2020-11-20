private_lane :smf_verify_and_lint_podspecs do |options|

  podspecs = options[:podspecs]

  return if podspecs.nil? || podspecs.count < 2

  podspecs.each do |podspec_path|

    UI.message("Linting podspec: #{podspec_path}")

    pod_lib_lint(
      allow_warnings: true,
      sources: $PODSPEC_REPO_SOURCES,
      podspec: podspec_path,
      fail_fast: true
    )
  end
end