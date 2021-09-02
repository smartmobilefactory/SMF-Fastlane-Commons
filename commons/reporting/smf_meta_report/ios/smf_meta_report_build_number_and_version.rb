
def smf_meta_report_build_number_and_version(build_variant)
  build_number = smf_get_build_number_of_app

  # only relevant for ios frameworks
  podspec_path = smf_config_get(build_variant, :podspec_path)

  # get the version number, podspec_path is only needed for ios frameworks
  version_number = smf_get_version_number(build_variant, podspec_path)

  unless @platform == :ios_framework
    build_number_string = "(#{build_number})"
  end

  "#{version_number} #{build_number_string}"
end