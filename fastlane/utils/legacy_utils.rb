# Uses Config file to access project name. Should be changed in the future.
def get_default_name_of_app(build_variant)
  build_number = get_build_number_of_app
  case @platform
  when :ios
    project_name = @smf_fastlane_config[:project][:project_name]
    "#{project_name} #{build_variant.upcase} (#{build_number})"
  when :android
    project_name = !@smf_fastlane_config[:project][:name].nil? ? @smf_fastlane_config[:project][:name] : ENV['PROJECT_NAME']
    "#{project_name} #{build_variant} (Build #{build_number})"
  when :flutter
    UI.message('Notification for flutter is not implemented yet')
  else
    UI.message("There is no platform \"#{@platform}\", exiting...")
    raise 'Unknown platform'
  end
end

# Uses Config file to access project name. Should be changed in the future.
def get_default_name_of_pod
  podspec_path = @smf_fastlane_config[:build_variants][@smf_build_variant_sym][:podspec_path]
  version = read_podspec(path: podspec_path)['version']
  pod_name = read_podspec(path: podspec_path)['name']
  project_name = !@smf_fastlane_config[:project][:project_name].nil? ? @smf_fastlane_config[:project][:project_name] : pod_name
  "#{project_name} #{version}"
end

# Uses Config file to access project name. Should be changed in the future.
def get_build_number_of_app
  UI.message('Get the build number of project.')
  case @platform
  when :ios
    project_name = @smf_fastlane_config[:project][:project_name]
    build_number = get_build_number(xcodeproj: "#{project_name}.xcodeproj")
  when :android
    build_number = @smf_fastlane_config['app_version_code'].to_s
  when :flutter
    UI.message('get build number of project for flutter is not implemented yet')
  else
    UI.message("There is no platform \"#{@platform}\", exiting...")
    raise 'Unknown platform'
  end

  if build_number.include? '.'
    parts = build_number.split('.')
    parts[0]
  else
    build_number
  end
end

def get_tag_of_pod(version_number)
  "releases/#{version_number}"
end

def get_app_secret(build_variant)
  UI.message("build_variant: #{build_variant}")
  build_variant = build_variant.to_s.downcase
  case @platform
  when :ios
    @smf_fastlane_config[:build_variants][build_variant.to_sym][:hockeyapp_id]
  when :android
    @smf_fastlane_config[:hockey][build_variant.to_sym]
  when :flutter
    UI.message('App Secret for flutter is not implemented yet')
  else
    UI.message("There is no platform \"#{@platform}\", exiting...")
    raise 'Unknown platform'
  end
end

def get_escaped_filename(build_variant)
  @smf_fastlane_config[:build_variants][build_variant.to_sym][:scheme].gsub(' ', "\ ")
end

def is_mac_app(build_variant)
  @smf_fastlane_config[:build_variants][build_variant.to_sym][:use_sparkle]
end

def get_path_to_ipa_or_app(build_variant)

  escaped_filename = get_escaped_filename(build_variant)

  app_path = Pathname.getwd.dirname.to_s + "/build/#{escaped_filename}.app.zip"
  app_path = Pathname.getwd.dirname.to_s + "/build/#{escaped_filename}.app" unless File.exist?(app_path)

  UI.message("Constructed path \"#{app_path}\" from filename \"#{escaped_filename}\"")

  unless File.exist?(app_path)
    app_path = lane_context[SharedValues::IPA_OUTPUT_PATH]

    UI.message("Using \"#{app_path}\" as app_path as no file exists at the constructed path.")
  end

  app_path
end

def get_podspec_path(build_variant)
  @smf_fastlane_config[:build_variants][build_variant.to_sym][:podspec_path]
end
