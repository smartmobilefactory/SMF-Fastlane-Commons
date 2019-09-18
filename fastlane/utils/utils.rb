def smf_get_apk_path(apk_file_regex)
  path = ''
  Dir["#{smf_workspace_dir}/**/#{apk_file_regex}"].each do |file|
    path = File.expand_path(file)
    UI.message("Found apk at: #{path}")
    break
  end
  path
end

def smf_get_apk_file_regex(build_variant)
  variant = smf_get_build_variant_from_config(build_variant)
  file_regex = "*-#{variant.gsub(/[A-Z]/) { |s| '-' + s.downcase }}.apk"
end

def smf_get_build_variant_from_config(build_variant)
  build_variant = build_variant.to_s.downcase
  variant = @smf_fastlane_config[:build_variants][build_variant.to_sym][:variant]
end

def smf_get_project_name
  @smf_fastlane_config[:project][:project_name]
end

def smf_get_appcenter_id(build_variant)
  build_variant = build_variant.to_s.downcase

  @smf_fastlane_config[:build_variants][build_variant.to_sym][:appcenter_id]
end

def smf_get_hockey_id(build_variant)
  build_variant = build_variant.to_s.downcase

  @smf_fastlane_config[:build_variants][build_variant.to_sym][:hockey_id]
end

def smf_get_default_name_of_app(build_variant)
  build_number = smf_get_build_number_of_app
  project_name = @smf_fastlane_config[:project][:project_name]

  "#{project_name} #{build_variant.upcase} (#{build_number})"
end

# Uses Config file to access project name. Should be changed in the future.
def smf_get_default_name_of_pod
  podspec_path = @smf_fastlane_config[:build_variants][@smf_build_variant_sym][:podspec_path]
  version = read_podspec(path: podspec_path)['version']
  pod_name = read_podspec(path: podspec_path)['name']
  project_name = !@smf_fastlane_config[:project][:project_name].nil? ? @smf_fastlane_config[:project][:project_name] : pod_name

  "#{project_name} #{version}"
end

# Uses Config file to access project name. Should be changed in the future.
def smf_get_build_number_of_app
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

def smf_get_xcconfig_name(build_variant)
  build_variant_config = @smf_fastlane_config[:build_variants][build_variant]
  use_xcconfig = build_variant_config[:xcconfig_name].nil? ? false : true
  use_xcconfig ? build_variant_config[:xcconfig_name][:archive] : 'Release'
end

def smf_get_icloud_environment(build_variant)
  build_variant_config = @smf_fastlane_config[:build_variants][build_variant]
  build_variant_config[:icloud_environment].nil? ? 'Development' : build_variant_config[:icloud_environment]
end

def smf_path_to_ipa_or_app(build_variant)

  escaped_filename = @smf_fastlane_config[:build_variants][build_variant.to_sym][:scheme].gsub(' ', "\ ")

  app_path = Pathname.getwd.dirname.to_s + "/build/#{escaped_filename}.ipa.zip"
  app_path = Pathname.getwd.dirname.to_s + "/build/#{escaped_filename}.ipa" unless File.exist?(app_path)

  UI.message("Constructed path \"#{app_path}\" from filename \"#{escaped_filename}\"")

  unless File.exist?(app_path)
    app_path = lane_context[SharedValues::IPA_OUTPUT_PATH]

    UI.message("Using \"#{app_path}\" as app_path as no file exists at the constructed path.")
  end

  app_path
end

def smf_ci_ios_error_log
  $SMF_CI_IOS_ERROR_LOG.to_s
end

def smf_git_pull(branch)
  branch_name = "#{branch}"
  branch_name.sub!('origin/', '')
  sh "git pull origin #{branch_name} --quiet"
end

def smf_update_config(config, message = nil)
  jsonString = JSON.pretty_generate(config)
  File.write("#{smf_workspace_dir}/Config.json", jsonString)
  git_add(path: "#{smf_workspace_dir}/Config.json")
  git_commit(path: "#{smf_workspace_dir}/Config.json", message: message || 'Update Config.json')
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

def smf_get_tag_of_pod(version_number)
  "releases/#{version_number}"
end

def smf_get_first_variant_from_config
  variant = @smf_fastlane_config[:build_variants].keys.map(&:to_s).first
  raise('There is no build variant in Config.') if variant.nil?

  variant
end

def smf_get_tag_of_app(build_variant, build_number)
  "build/#{build_variant.downcase}/#{build_number}"
end

def smf_get_version_number(build_variant)
  build_variant_config = @smf_fastlane_config[:build_variants][build_variant.to_sym]
  target = build_variant_config[:target]
  scheme = build_variant_config[:scheme]

  version_number = get_version_number(
      xcodeproj: "#{smf_get_project_name}.xcodeproj",
      target: (target != nil ? get_target : scheme)
  )

  return version_number
end