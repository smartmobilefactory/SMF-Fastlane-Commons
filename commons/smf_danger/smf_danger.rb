private_lane :smf_danger do |options|

  checkstyle_paths = []
  podspec_path = options[:podspec_path]
  bump_type = options[:bump_type]

  if File.exist?(smf_swift_lint_output_path)
    checkstyle_paths.push(smf_swift_lint_output_path)
  elsif [:ios, :ios_framework, :macos, :apple].include?(@platform)
    UI.important("There is not SwiftLint output file at #{smf_swift_lint_output_path}. Is SwiftLint enabled?")
  end

  if @platform == :android
    UI.user_error!("android-commons not present! Can't start danger") unless File.exist?('../android-commons')
  end

  lint_paths = _smf_find_paths_of('lint-result.xml')
  junit_result_paths = _smf_find_paths_of_files_in_directory('build/test-results', 'xml')

  _smf_find_paths_of('ktlint.xml').each { |path| checkstyle_paths.push(path) }
  _smf_find_paths_of('detekt.xml').each { |path| checkstyle_paths.push(path) }
  _smf_find_paths_of('flutter_analyzer.xml').each { |path| checkstyle_paths.push(path) }

  ENV['DANGER_ANDROID_LINT_PATHS'] = JSON.dump(lint_paths)
  ENV['DANGER_JUNIT_PATHS'] = JSON.dump(junit_result_paths)
  ENV['DANGER_CHECKSTYLE_PATHS'] = JSON.dump(checkstyle_paths)

  if (@platform == :ios_framework && !bump_type.nil?)
    if bump_type == 'NO_BUMP_TYPE_ERROR'
      ENV['NO_BUMP_TYPE_ERROR'] = 'true'
    elsif bump_type == 'MULTIPLE_BUMP_TYPES_ERROR'
      ENV['MULTIPLE_BUMP_TYPES_ERROR'] = 'true'
    else
      version_number = smf_increment_version_number_dry_run(
          podspec_path: podspec_path,
          bump_type: bump_type
      )

      ENV['POD_VERSION'] = version_number
    end
  end

  _check_common_project_setup_files

  _smf_create_jira_ticket_links

  _swift_lint_count_unused_rules

  # Clean up repo and Config.json
  _smf_check_config_project_keys
  _smf_check_repo_files_folders
  _smf_check_config_build_variant_keys

  danger(
      github_api_token: ENV[$DANGER_GITHUB_TOKEN_KEY],
      dangerfile: "#{File.expand_path(File.dirname(__FILE__))}/Dangerfile",
      verbose: true
  )
end

def _smf_check_repo_files_folders
  active_files_to_remove = []
  _smf_deprecated_files_for_platform.each do |deprecated_file|
    # Check if the files exist within the repo
    if File.exist?("#{smf_workspace_dir}/#{deprecated_file}")
      # if so retain the file and warn developers in PR checks.
      active_files_to_remove.push(deprecated_file)
    end
  end

  ENV['DANGER_REPO_CLEAN_UP_FILES'] = JSON.dump(active_files_to_remove)
end

def _smf_deprecated_files_for_platform
  deprecated_files = $CONFIG_DEPRECATED_FILES_FOLDERS_COMMONS
  case @platform
  when :ios, :ios_framework, :macos, :apple
    deprecated_files += $CONFIG_DEPRECATED_FILES_FOLDERS_IOS
  when :android
    deprecated_files += $CONFIG_DEPRECATED_FILES_FOLDERS_ANDROID
  when :flutter
    deprecated_files += $CONFIG_DEPRECATED_FILES_FOLDERS_FLUTTER
  else
    UI.message("There is no platform \"#{@platform}\", exiting...")
    raise "Unknown platform: #{@platform.to_s}"
  end

  deprecated_files
end

def _smf_check_config_project_keys
  project_config = @smf_fastlane_config[:project]
  if project_config.nil?
    UI.error("[ERROR]: Missing 'project' info in Config.json")
  end

  required_keys = _smf_required_config_keys_for_platform
  deprecated_keys = []
  project_config.keys.each do |key|
    unless required_keys.include?(key)
      deprecated_keys.push(key)
    end
  end

  ENV['DANGER_REPO_CLEAN_UP_PROJECT_CONFIG_KEYS'] = JSON.dump(deprecated_keys)
end

def _smf_required_config_keys_for_platform
  required_keys = $CONFIG_REQUIRED_PROJECT_KEYS_COMMONS
  case @platform
  when :ios, :ios_framework, :macos, :apple
    required_keys += $CONFIG_REQUIRED_PROJECT_KEYS_IOS
  when :android
    required_keys += $CONFIG_REQUIRED_PROJECT_KEYS_ANDROID
  when :flutter
    required_keys += $CONFIG_REQUIRED_PROJECT_KEYS_FLUTTER
  else
    UI.message("There is no platform \"#{@platform}\", exiting...")
    raise "Unknown platform: #{@platform.to_s}"
  end

  required_keys
end

def _smf_check_config_build_variant_keys
  config = JSON.parse(File.read("#{smf_workspace_dir}/Config.json"), :symbolize_names => false)
  build_variants = config['build_variants']
  if build_variants.nil? || build_variants.count == 0
    UI.error("[ERROR]: Missing or empty 'build_variants' in Config.json")
  end

  deprecated_keys = _smf_deprecated_build_variant_keys_for_platform
  deprecated_keys_in_variant = []
  build_variants.each do |build_variant, build_variant_info|
    build_variant_info.keys.each do |key|
      if deprecated_keys.include?(key)
        deprecated_keys_in_variant.push("#{build_variant}.#{key}")
      end
    end
  end

  ENV['DANGER_REPO_CLEAN_UP_BUILD_VARIANTS'] = JSON.dump(deprecated_keys_in_variant)
end

def _smf_deprecated_build_variant_keys_for_platform
  deprecated_keys = []
  case @platform
  when :ios, :ios_framework, :macos, :apple
    deprecated_keys = $CONFIG_DEPRECATED_BUILD_VARIANT_KEYS_IOS
  when :android
    deprecated_keys = $CONFIG_DEPRECATED_BUILD_VARIANT_KEYS_ANDROID
  when :flutter
    deprecated_keys = $CONFIG_DEPRECATED_BUILD_VARIANT_KEYS_FLUTTER
  else
    UI.message("There is no platform \"#{@platform}\", exiting...")
    raise 'Unknown platform: "#{@platform.to_s}"'
  end

  deprecated_keys
end

def _swift_lint_count_unused_rules

  if File.exist?(smf_swift_lint_rules_report_path)
    line_count = `wc -l "#{smf_swift_lint_rules_report_path}"`.strip.split(' ')[0].to_i
    # In the report, there is a total of 4 lines used as format for the document (header/footer)
    # Remove them from the total line count to get an exact number of unused swiftlint rules.
    line_count = (line_count - 4)
    if line_count > 0
      file_path = smf_swift_lint_rules_report_path.sub(smf_workspace_dir, '')
      report_URL = "#{ENV['BUILD_URL']}/execution/node/3/ws/#{file_path}"
      href = "<a href=\"#{report_URL}\" target=\"_blank\">#{file_path}</a>"
      message = "There is a total of <b>#{line_count}</b> unused Swiftlint rules!<br>Please check the generated report directly on Jenkins: #{href}"
      ENV['DANGER_SWIFT_LINT_RULES_REPORT'] = message
    end
  elsif [:ios, :ios_framework, :macos, :apple].include?(@platform)
    UI.important("There is no SwiftLint rules report at #{smf_swift_lint_rules_report_path}. Is SwiftLint enabled?")
  end
end

def _check_common_project_setup_files
  submodule_directory = File.join(smf_workspace_dir, 'Submodules/SMF-iOS-CommonProjectSetupFiles')

  return unless Dir.exist?(submodule_directory)

  current_head_commit = `cd #{submodule_directory}; git rev-parse HEAD`.gsub("\n", '')
  remote_head_commit = `cd #{submodule_directory}; git rev-parse origin/master`.gsub("\n", '')

  if current_head_commit != remote_head_commit
    ENV['COMMON_PROJECT_SETUP_FILES_OUTDATED'] = 'true'
  end
end

def _smf_find_paths_of(filename)
  paths = []
  Dir["#{smf_workspace_dir}/**/#{filename}"].each do |file|
    paths.push(File.expand_path(file))
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

def _smf_create_jira_ticket_links

  contexts_to_search = {
      :titel => ENV['PR_TITLE'],
      :body => ENV['PR_BODY'],
      :commits => ENV['COMMITS'].nil? ? nil : ENV['COMMITS'].gsub('[', '').gsub(']', '').split(', '),
      :branch_name => ENV['CHANGE_BRANCH']
  }

  ticket_tags = smf_find_jira_ticket_tags_in_pr(contexts_to_search)
  tickets = smf_generate_tickets_from_tags(ticket_tags)

  html_formatted_tickets = _smf_generate_changelog(nil, tickets, :html)

  ENV['DANGER_JIRA_TICKETS'] = html_formatted_tickets
end