def smf_get_file_path(file_regex)
  path = ''
  Dir["#{smf_workspace_dir}/**/#{file_regex}"].each do |file|
    path = File.expand_path(file)
    break
  end
  path
end

def smf_get_file_paths(file_regex)
  paths = []
  Dir["#{smf_workspace_dir}/**/#{file_regex}"].each do |file|
    paths.append(File.expand_path(file))
  end
  paths
end

def smf_get_ouput_file_regex(build_variant)
  case @platform
  when :android
    variant = smf_get_build_variant_from_config(build_variant)
    file_regex = "*-#{variant.gsub(/[A-Z]/) { |s| '-' + s.downcase }}"
  when :flutter
    file_regex = "app-#{build_variant}-release"
  end

  file_regex
end

def smf_get_apk_file_regex(build_variant)
  "#{smf_get_ouput_file_regex(build_variant)}.apk"
end

def smf_get_aab_file_regex(build_variant)
  "#{smf_get_ouput_file_regex(build_variant)}.aab"
end

def smf_get_build_variant_from_config(build_variant)
  @smf_fastlane_config[:build_variants][build_variant.to_sym][:variant]
end

def smf_get_appcenter_destination_groups(build_variant, additional_destinations)
  destinations = []

  unless additional_destinations.nil?
    destinations = destinations + additional_destinations.split(',')
  end

  if build_variant.downcase.include? 'alpha'
    destinations.push('All-Alphas-2eff8581')
  end

  destinations.push('Collaborators')

  destinations.uniq.join(',')
end

def smf_get_appcenter_id(build_variant, platform = nil)
  appcenter_id = smf_config_get(build_variant, :appcenter_id)
  appcenter_id = smf_config_get(build_variant, platform.to_sym, :appcenter_id) unless platform.nil?

  appcenter_id
end

def smf_get_keystore_folder(build_variant)

  @smf_fastlane_config[:build_variants][build_variant.to_sym][:keystore]
end

def smf_get_default_name_and_version(build_variant)
  project_name = smf_config_get(nil, :project, :project_name)

  # Simply return the projects name if no build variant is given / its nil
  return project_name unless build_variant

  build_number = smf_get_build_number_of_app

  # only relevant for ios frameworks
  podspec_path = smf_config_get(build_variant, :podspec_path)

  # get the version number, podspec_path is only needed for ios frameworks
  version_number = smf_get_version_number(build_variant, podspec_path)

  unless @platform == :ios_framework
    build_variant_string = "#{build_variant.upcase} "
    build_number_string = "(#{build_number})"
  end

  "#{project_name} #{build_variant_string}#{version_number} #{build_number_string}".strip
end

def smf_get_build_number_of_app
  UI.message('Get the build number of project.')
  case @platform
  when :ios, :macos, :apple
    project_name = @smf_fastlane_config[:project][:project_name]
    build_number = get_build_number(xcodeproj: smf_get_xcodeproj_file_name)
  when :android
    build_number = @smf_fastlane_config[:app_version_code].to_s
  when :flutter
    build_number = YAML.load(File.read("#{smf_workspace_dir}/pubspec.yaml"))['version'].split('+').last
  when :ios_framework
    # No build number for frameworks
    build_number = ''
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

def smf_path_to_app_file

  if !ENV['APP_NAME'].nil?
    UI.message("Using app name: #{ENV['APP_NAME']} from Info.plist to construct .app path")
    return smf_workspace_dir + "/build/#{ENV['APP_NAME']}.app"
  end

  app_path = nil

  Dir.foreach(smf_workspace_dir + '/build') do |filename|

    file_exists = filename.end_with?('.app')

    if file_exists
      app_path = smf_workspace_dir + '/build/' + filename
      break
    end
  end

  app_path
end

def smf_path_to_ipa_or_app

  if !ENV['APP_NAME'].nil?
    UI.message("Using app name: #{ENV['APP_NAME']} from Info.plist to construct .app path")
    return smf_workspace_dir + "/build/#{ENV['APP_NAME']}.app"
  end

  app_path = ''

  Dir.foreach(smf_workspace_dir + '/build') do |filename|
    file_exists = filename.end_with?('.ipa.zip')
    file_exists = filename.end_with?('.ipa') unless file_exists
    file_exists = filename.end_with?('.app') unless file_exists

    if file_exists
      app_path = smf_workspace_dir + '/build/' + filename
      break
    end
  end

  unless File.exist?(app_path)
    app_path = lane_context[SharedValues::IPA_OUTPUT_PATH]

    UI.message("Using \"#{app_path}\" as app_path as no file exists at the constructed path.")
  end

  app_path
end

def smf_rename_app_file(build_variant)

  app_file_path = smf_path_to_ipa_or_app
  info_plist_path = File.join(app_file_path,"/Contents/Info.plist").shellescape

  app_name= sh("defaults read #{info_plist_path} CFBundleName").gsub("\n", '')
  ENV['APP_NAME'] = app_name

  new_app_file_path = smf_path_to_ipa_or_app

  UI.message("Renaming #{app_file_path} to #{new_app_file_path}")
  File.rename(app_file_path, new_app_file_path)
end

def smf_path_to_dmg(build_variant)
  app_path = smf_path_to_ipa_or_app
  dmg_path = app_path.sub('.app', '.dmg')

  dmg_path
end

def smf_ci_ios_error_log
  $SMF_CI_IOS_ERROR_LOG.to_s
end

def smf_ci_flutter_error_log
  $SMF_CI_FLUTTER_ERROR_LOG.to_s
end

def smf_git_pull(branch)
  branch_name = "#{branch}"
  branch_name.sub!('origin/', '')
  sh "git pull origin #{branch_name} --depth=5 --quiet --allow-unrelated-histories -X theirs"
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

def smf_get_tag_of_pod(podspec_path)
  version_number = smf_get_version_number(nil, podspec_path)
  "releases/#{version_number}"
end

def smf_get_tag_of_app(build_variant, build_number)
  "build/#{build_variant.downcase}/#{build_number}"
end

def smf_get_version_number(build_variant = nil, podspec_path = nil)

  case @platform
  when :ios, :macos, :apple
    raise "Cannot find marketing version" if build_variant.nil?

    target = smf_config_get(build_variant, :target)
    scheme = smf_config_get(build_variant, :scheme)
    configuration = smf_config_get(build_variant, :xcconfig_name, :archive)
    configuration = 'Release' if configuration.nil?

    begin
      # First we try to get the version number from the plist via fastlane
      version_number = get_version_number(
          xcodeproj: smf_get_xcodeproj_file_name,
          target: (target.nil? ? scheme : target),
          configuration: configuration
      )
    rescue
      begin
          # Depending on the project configuration, we might have the version number as a variable in the plist
          # If that's the case, fastlane won't manage to get it, and we'll endup here.
          # The next strategy is to check for MARKETING_VERSION in the build configuration
          UI.message("Fastlane was not able to determine project version. Checking now for MARKETING_VERSION in the build settings")

          # First we make sure that we are using the correct Xcode version
          required_xcode_version = smf_config_get(nil, :project, :xcode_version)
          smf_setup_correct_xcode_executable_for_build(required_xcode_version: required_xcode_version)

          project_name = @smf_fastlane_config[:project][:project_name]
          workspacePath = "#{smf_workspace_dir}/#{project_name}.xcworkspace"
          buildConfigurationString = `xcodebuild -workspace "#{workspacePath}" -scheme "#{scheme}" -configuration "#{configuration}" -showBuildSettings -json`
          buildConfigurationJSON = JSON.parse(buildConfigurationString)
          version_number = buildConfigurationJSON.first['buildSettings']["MARKETING_VERSION"]
          UI.message("Found MARKETING_VERSION in the build settings: #{version_number}")
      rescue StandardError => e
          raise "Cannot find marketing version #{e}"
      rescue
          raise "Cannot find marketing version"
      end
    end
  when :ios_framework
    begin
      # This fails if the version contains anything but digits in the first three components
      version_number = version_get_podspec(path: podspec_path)
    rescue
      # If the above failed, use simple regex to find the version in the podspec
      podspec_content = File.read(File.join(smf_workspace_dir, podspec_path))
      version_regex = /version\s+=\s"(?<version>.+)"/i
      version_number = podspec_content.match(version_regex)[:version]
    end

  when :android
    version_number = nil
  when :flutter
    version_number = YAML.load(File.read("#{smf_workspace_dir}/pubspec.yaml"))['version'].split('+').first
  else
    UI.message("There is no platform \"#{@platform}\", exiting...")
    raise 'Unknown platform'
  end
  UI.message("Use #{version_number} as version number.")
  version_number
end

def smf_extract_bump_type_from_pr_body

  pr_body = ENV['PR_BODY']

  matches = pr_body.scan(/- \[x\] \*\*(nothing|patch|minor|major|current|internal|breaking)\*\*/) unless pr_body.nil?

  if matches.nil? || matches.empty?
    UI.error("No bump type selected!")
    return 'NO_BUMP_TYPE_ERROR'
  end

  if matches.size > 1
    UI.error("More then one bump types checkmarked in PR description!")
    return 'MULTIPLE_BUMP_TYPES_ERROR'
  end

  bump_type = matches.first.first

  if !bump_type.nil?
    if $POD_DEFAULT_VARIANTS.include?(bump_type)
      return bump_type
    end
  end

  nil
end

def smf_get_flutter_binary_path

  submodule_status = sh "cd #{smf_workspace_dir} && git submodule status"
  matcher = submodule_status.match(/(.+) .*flutter/m)

  if matcher.nil? || matcher.captures.nil? || matcher.captures.size != 1
    error_message = "Unable to find sha1 of submodule 'flutter' to look up flutter binary in cache"
    UI.error(error_message)
    raise error_message
  end

  flutter_sha = matcher.captures[0].gsub(' ', '')

  user_root_dir = ENV['HOME']
  flutter_cache_base = "#{user_root_dir}/.flutter_cache"
  flutter_repo_path = "#{user_root_dir}/.flutter_cache/#{flutter_sha}"
  flutter_binary_path = flutter_repo_path + "/bin/flutter"

  if !File.exist?(flutter_binary_path)
    sh "mkdir -p #{flutter_cache_base} && git clone git@github.com:flutter/flutter.git #{flutter_repo_path} && cd #{flutter_repo_path} && git checkout #{flutter_sha}"
    UI.message("Updated flutter binray cache")
  else
    UI.message("Using flutter binary from cache 🎉")
  end

  return flutter_binary_path
end

def smf_build_variant(options)
  build_variant = options[:build_variant]
  return build_variant unless build_variant.nil?

  smf_get_first_variant_from_config
end

# converts an array wrapped into a string (for example '["test", "test2"]')
# into an array
def smf_string_array_to_array(string)
  return nil if string.nil?

  array = string.delete(' ').delete('[').delete(']')
  array.split(',')
end

def smf_workspace_dir_git_branch
  current_branch = `cd #{smf_workspace_dir}; git rev-parse --abbrev-ref HEAD`.gsub("\n", '')
  return current_branch
end

# Returns array with all versions found
def smf_get_podspec_versions(podspecs)
  return [] if podspecs.nil? || podspecs.count < 0
  return [read_podspec(path: podspecs.first).dig('version')] if podspecs.count == 1

  versions = []

  podspecs.each do |podspecs_path|
    version = read_podspec(path: podspecs_path).dig('version')
    versions.push(version) unless version.nil?
  end

  versions.uniq
end

def smf_is_keychain_enabled
  return ENV[$SMF_IS_KEYCHAIN_ENABLED].nil? ? true : ENV[$SMF_IS_KEYCHAIN_ENABLED] == "true"
end

def _try_dig(map, key)

  begin
    value = map.dig(key)
  rescue
    value = nil
  end

  value
end