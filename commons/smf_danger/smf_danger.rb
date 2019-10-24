private_lane :smf_danger do |options|

  jira_keys = options[:jira_key]
  checkstyle_paths = []
  build_variant = options[:build_variant]

  if File.exist?(smf_swift_lint_output_path)
    checkstyle_paths.push(smf_swift_lint_output_path)
  elsif [:ios, :ios_framework].include?(@platform)
    UI.important("There is not SwiftLint output file at #{smf_swift_lint_output_path}. Is SwiftLint enabled?")
  end

  if @platform == :android
    UI.user_error!("android-commons not present! Can't start danger") unless File.exist?('../android-commons')
  end

  lint_paths = _smf_find_paths_of('lint-result.xml')
  junit_result_paths = _smf_find_paths_of_files_in_directory('build/test-results', 'xml')

  _smf_find_paths_of('klint.xml').each { |path| checkstyle_paths.push(path) }
  _smf_find_paths_of('detekt.xml').each { |path| checkstyle_paths.push(path) }

  ENV["DANGER_JIRA_KEYS"] = JSON.dump(_smf_danger_jira_key_parameter(jira_keys))
  ENV["DANGER_ANDROID_LINT_PATHS"] = JSON.dump(lint_paths)
  ENV["DANGER_JUNIT_PATHS"] = JSON.dump(junit_result_paths)
  ENV["DANGER_CHECKSTYLE_PATHS"] = JSON.dump(checkstyle_paths)

  ENV["BUILD_VERSION"] = smf_get_version_number(build_variant)
  ENV["BUILD_VARIANT"] = build_variant

  danger(
      github_api_token: ENV["DANGER_GITHUB_API_TOKEN"],
      dangerfile: "#{File.expand_path(File.dirname(__FILE__))}/Dangerfile",
      verbose: true,
      danger_id: build_variant
  )
end

def _smf_danger_jira_key_parameter(jira_keys_parameter)
  jira_keys = !jira_keys_parameter.nil? ? jira_keys_parameter : []

  keys = []
  jira_keys.each do |key|
    if key.is_a?(String)
      if !key.nil? && key != ''
        keys.append(
            {
                'key' => key,
                'url' => 'https://smartmobilefactory.atlassian.net/browse'
            }
        )
      end
    elsif !key.nil? && !key['key'].nil? && !key['url'].nil?
      keys.append(key)
    end
  end

  keys
end

def _smf_find_paths_of(filename)
  paths = []
  Dir["#{smf_workspace_dir}/**/#{filename}"].each do |file|
    paths.append(File.expand_path(file))
  end
  paths
end

def _smf_find_paths_of_files_in_directory(directory, file_type = '')
  paths = []
  file_type = ".#{file_type}" if file_type != ''
  Dir["#{smf_workspace_dir}/**/#{directory}/*#{file_type}"].each do |file|
    paths.append(File.expand_path(file))
  end
  paths
end