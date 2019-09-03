def get_apk_path(apk_file_regex)
  Dir["/**/#{apk_file_regex}"].each do |file|
    path = File.path(file)
    break
  end
end

def get_apk_file_regex(build_variant)
  variant = get_build_variant_from_config(build_variant)
  file_regex = "*-#{variant.gsub(/[A-Z]/).map(&:downcase).join('-')}.apk"
end

def get_build_variant_from_config(build_variant)
  build_variant = build_variant.to_s.downcase
  @smf_fastlane_config[:build_variants][build_variant.to_sym]['variant']
end