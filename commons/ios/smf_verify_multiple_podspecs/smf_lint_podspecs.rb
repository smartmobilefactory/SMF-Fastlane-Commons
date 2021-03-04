private_lane :smf_lint_podspecs do |options|

  main_podspec = options[:main_podspec]
  additional_podspecs = options[:additional_podspecs]
  required_xcode_version = options[:required_xcode_version]

  next if additional_podspecs.nil? || additional_podspecs.count < 1

  smf_setup_correct_xcode_executable_for_build(required_xcode_version: required_xcode_version)

  UI.message("Linting all podspecs")

  pod_lib_lint(
    allow_warnings: true,
    sources: $PODSPEC_REPO_SOURCES,
    podspec: '*.podspec',
    include_podspecs: '*.podspec',
    fail_fast: true
  )

  # additional_podspecs.each do |additional_podspec_path|

  #   UI.message("Linting podspec: #{additional_podspec_path}")

  #   pod_lib_lint(
  #     allow_warnings: true,
  #     sources: $PODSPEC_REPO_SOURCES,
  #     podspec: additional_podspec_path,
  #     # We need `include_podspecs` here to be able to use our local `main_podspec` for the lint. 
  #     # If we don't specify it, it will use the `main_podspec` corresponding to the version number in `additional_podspec_path`, making the lint fail.
  #     include_podspecs: '*.podspec',
  #     fail_fast: true
  #   )
  # end
end