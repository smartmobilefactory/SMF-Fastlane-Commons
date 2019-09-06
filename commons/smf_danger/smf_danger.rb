private_lane :smf_danger do |options|

  UI.user_error!("android-commons not present! Can't start danger") unless File.exist?('../android-commons')

  lint_paths = smf_find_paths_of("lint-result.xml")
  junit_result_paths = smf_find_paths_of_files_in_directory('build/test-results', 'xml')
  checkstyle_paths = []
  checkstyle_paths.append(smf_find_paths_of("klint.xml"))
  checkstyle_paths.append(smf_find_paths_of("detekt.xml"))

  ENV['DANGER_JIRA_KEYS'] = JSON.dump(smf_danger_jira_key_parameter(options[:jira_key]))
  ENV['DANGER_LINT_PATHS'] = JSON.dump(lint_paths)
  ENV['DANGER_JUNIT_PATHS'] = JSON.dump(junit_result_paths)
  ENV['DANGER_CHECKSTYLE_PATHS'] = JSON.dump(checkstyle_paths)

  danger(
      github_api_token: ENV['DANGER_GITHUB_API_TOKEN'],
      dangerfile: "#{@fastlane_commons_dir_path}/danger/Dangerfile",
      verbose: true
  )
end

def smf_danger_jira_key_parameter(jira_keys)
  # Set environment variables for danger if options parameter are present
  jira_keys = [jira_keys] unless jira_keys.is_a?(Array)

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

def smf_find_paths_of(filename)
  paths = []
  Dir["#{smf_workspace_dir}/**/#{filename}"].each do |file|
    UI.message("Found file at: #{File.expand_path(file)}")
    paths.append(File.expand_path(file))
  end
  paths
end

def smf_find_paths_of_files_in_directory(directory, file_type = '')
  paths = []
  file_type = ".#{file_type}" if file_type != ''
  Dir["#{smf_workspace_dir}/**/#{directory}/*#{file_type}"].each do |file|
    UI.message("Found file at: #{File.expand_path(file)}")
    paths.append(File.expand_path(file))
  end
  paths
end