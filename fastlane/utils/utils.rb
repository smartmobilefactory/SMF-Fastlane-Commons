def get_apk_path(apk_file_regex)
  path = ''
  Dir["#{smf_workspace_dir}/**/#{apk_file_regex}"].each do |file|
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
  file_regex
end

def get_build_variant_from_config(build_variant)
  build_variant = build_variant.to_s.downcase
  variant = @smf_fastlane_config[:build_variants][build_variant.to_sym][:variant]

  variant
end

def get_project_name
  @smf_fastlane_config[:project][:project_name]
end

def get_app_secret(build_variant)
  build_variant = build_variant.to_s.downcase
  case @platform
  when :ios
    @smf_fastlane_config[:build_variants][build_variant.to_sym][:appcenter_id]
  when :android
    @smf_fastlane_config[:build_variants][build_variant.to_sym][:appcenter_id]
  when :flutter
    UI.message('App Secret for flutter is not implemented yet')
  else
    UI.message("There is no platform \"#{@platform}\", exiting...")
    raise 'Unknown platform'
  end
end