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

def smf_get_default_name_of_app(build_variant)
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

def smf_get_default_name_of_pod
  podspec_path = @smf_fastlane_config[:build_variants][@smf_build_variant_sym][:podspec_path]
  version = read_podspec(path: podspec_path)['version']
  pod_name = read_podspec(path: podspec_path)['name']
  project_name = !@smf_fastlane_config[:project][:project_name].nil? ? @smf_fastlane_config[:project][:project_name] : pod_name
  "#{project_name} #{version}"
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

def update_config(config, message = nil)
  jsonString = JSON.pretty_generate(config)
  File.write("#{smf_workspace_dir}/Config.json", jsonString)
  git_add(path: "#{smf_workspace_dir}/Config.json")
  git_commit(path: "#{smf_workspace_dir}/Config.json", message: message || "Update Config.json")
end

def smf_danger_module_config(options)
  module_basepath = !options[:module_basepath].nil? ? options[:module_basepath] : ''
  run_detekt = !options[:run_detekt].nil? ? options[:run_detekt] : true
  run_ktlint = !options[:run_ktlint].nil? ? options[:run_ktlint] : true
  junit_task = options[:junit_task]

  modules = !options[:modules].nil? ? options[:modules] : []

  if modules.empty?
    modules.push(
        {
            'module_name' => module_basepath,
            'run_detekt' => run_detekt,
            'run_ktlint' => run_ktlint,
            'junit_task' => junit_task
        }
    )
  end

  modules
end