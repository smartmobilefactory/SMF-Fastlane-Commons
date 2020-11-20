private_lane :smf_verify_and_lint_podspecs do |options|

  podpecs = options[:podspecs]

  return if podpecs.nil? || podpecs.count < 2

  podpecs.each do |podspec_path|

    UI.message("Linting podspec: #{podspec_path}")

    pod_lib_lint(
      allow_warnings: true,
      sources: $POD_REPO_SOURCES,
      podpec: podspec_path,
      fail_fast: true
    )
  end
end