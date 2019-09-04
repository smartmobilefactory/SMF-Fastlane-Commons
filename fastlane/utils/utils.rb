def get_apk_path(apk_file_regex)
  path = ''
  Dir['/'].each do |file|
    UI.message(file.basename)
  end
  Dir["/**/#{apk_file_regex}"].each do |file|
    path = File.expand_path(file)
    UI.message("Found apk at: #{path}")
    break
  end
  path
end

def get_apk_file_regex(build_variant)
  variant = get_build_variant_from_config(build_variant)
  file_regex = "*-#{variant.gsub(/[A-Z]/) { |s| '-' + s.downcase }}.apk"
  UI.message("Apk File Regex: #{file_regex}")
end

def get_build_variant_from_config(build_variant)
  build_variant = build_variant.to_s.downcase
  variant = @smf_fastlane_config[:build_variants][build_variant.to_sym][:variant]

  variant
end