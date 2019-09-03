def get_apk_path(apk_file_regex)
  Dir["/**/#{apk_file_regex}"].each do |file|
    UI.message("Found apk at: #{File.path(file)}")
    path = File.path(file)
    break
  end
end

def get_apk_file_regex(build_variant)
  variant = get_build_variant_from_config(build_variant)
  file_regex = "*-#{variant.gsub(/[A-Z]/) { |s| '-' + s.downcase }}.apk"
  UI.message("Apk File Regex: #{file_regex}")
end

def get_build_variant_from_config(build_variant)
  build_variant = build_variant.to_s.downcase
  UI.message("Build variant: #{build_variant}")
  UI.message("Config: #{@smf_fastlane_config}")
  variant = @smf_fastlane_config[:build_variants][build_variant.to_sym]['variant']
  UI.message("Variant: #{variant}")
end