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
end

def get_build_variant_from_config(build_variant)
  build_variant = build_variant.to_s.downcase
  variant = @smf_fastlane_config[:build_variants][build_variant.to_sym][:variant]
end

def get_project_name
  @smf_fastlane_config[:project][:project_name]
end

def get_app_center_id(build_variant)
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

def get_default_name_of_app(build_variant)
  build_number = get_build_number_of_app
  project_name = @smf_fastlane_config[:project][:project_name]
  case @platform
  when :ios
    "#{project_name} #{build_variant.upcase} (#{build_number})"
  when :android
    "#{project_name} #{build_variant} (Build #{build_number})"
  when :flutter
    UI.message('Notification for flutter is not implemented yet')
  else
    UI.message("There is no platform \"#{@platform}\", exiting...")
    raise 'Unknown platform'
  end
end

def get_build_number_of_app
  UI.message('Get the build number of project.')
  case @platform
  when :ios
    project_name = @smf_fastlane_config[:project][:project_name]
    build_number = get_build_number(xcodeproj: "#{project_name}.xcodeproj")
  when :android
    build_number = @smf_fastlane_config[:app_version_code].to_s
  when :flutter
    UI.message('get build number of project for flutter is not implemented yet')
  else
    UI.message("There is no platform \"#{@platform}\", exiting...")
    raise 'Unknown platform'
  end

  if build_number.include? '.'
    parts = build_number.split('.')
    build_number = parts[0]
  end

  build_number
end