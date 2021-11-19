private_lane :smf_danger do |options|

  checkstyle_paths = []
  podspec_path = options[:podspec_path]
  bump_type = options[:bump_type]

  if File.exist?(smf_swift_lint_output_xml_path)
    checkstyle_paths.push(smf_swift_lint_output_xml_path)
  elsif _is_apple_platform
    UI.important("There is no SwiftLint output file at #{smf_swift_lint_output_xml_path}. Is SwiftLint enabled?")
  end

  if File.exist?(smf_swift_lint_analyze_xml_path)
    checkstyle_paths.push(smf_swift_lint_analyze_xml_path)
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

  ENV['DANGER_RESULT_BUNDLE_PATH'] = $IOS_RESULT_BUNDLE_PATH

  _check_common_project_setup_files

  _smf_create_jira_ticket_links

  _swift_lint_count_unused_rules

  # Clean up repo and Config.json
  # See file: smf_danger_repo_clean_up.rb
  _smf_check_config_project_allowed_only_keys
  _smf_check_config_project_missing_required_keys
  _smf_check_repo_files_folders
  _smf_check_config_build_variant_keys
  _smf_check_valid_xcode_config(options)
  _smf_extract_thread_sanitizer_warnings

  dangerfile = "#{File.expand_path(File.dirname(__FILE__))}/Dangerfile"
  puts "Loading Dangerfile: #{dangerfile}"
  danger(
      github_api_token: ENV[$DANGER_GITHUB_TOKEN_KEY],
      dangerfile: dangerfile,
      verbose: true
  )
end

def _is_apple_platform
  return [:ios, :ios_framework, :macos, :apple].include?(@platform)
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
  elsif _is_apple_platform
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

def _smf_check_valid_xcode_config(options)
  unless _is_apple_platform
    return
  end

  xcode_settings = smf_xcodeproj_settings(options)
  # If invalid, set warning under env 'DANGER_ENABLE_BITCODE'
  smf_analyse_bitcode(xcode_settings, options)
  # If invalid, set warning under env 'DANGER_SWIFT_VERSION'
  smf_analyse_swift_version(xcode_settings, options)
  # If invalid, set warning(s) for the invalid deployment target(s):
  # env: 'DANGER_IPHONEOS_DEPLOYMENT_TARGET'
  # env: 'DANGER_MACOSX_DEPLOYMENT_TARGET'
  # env: 'DANGER_TVOS_DEPLOYMENT_TARGET'
  # env: 'DANGER_WATCHOS_DEPLOYMENT_TARGET'
  smf_analyse_deployment_targets(xcode_settings, options)
end

def _smf_extract_thread_sanitizer_warnings
  unless _is_apple_platform
    return
  end

  # Load unit test log file
  unit_tests_logs_directory = File.join(smf_workspace_dir, $IOS_UNIT_TESTS_BUILD_LOGS_DIRECTORY)

  sanitizer_warning = _smf_extract_thread_sanitizer_warnings_from_directory(unit_tests_logs_directory)

  if !sanitizer_warning.nil? 
    content = "**Thread sanitizer found issues while running unit tests**\n\n**Please run the unit tests on your local machine with the thread sanitizer enabled and fix the issues**\n\n```\n#{sanitizer_warning}\n```\n"
    ENV['DANGER_SANITIZER_WARNINGS'] = content
  end
end

# unit_tests_logs_directory: full path to the logs directory. The function will look for the first `.log` file in the given directory and use it.
def _smf_extract_thread_sanitizer_warnings_from_directory(unit_tests_logs_directory) 
  log_file = Dir["#{unit_tests_logs_directory}/*.log"].first

  # Infos:
  # Sanitizer warnings start with:
  # ==================
  # WARNING: ThreadSanitizer:
  #
  # And ends with:
  # ==================

  # This command returns: `lineNumber-WARNING: ThreadSanitizer` -> `cut` takes care of removing everything except the line number
  start_line_string = `grep "==================" -n -A 1 #{log_file} | grep "WARNING: ThreadSanitizer" | cut -f1 -d-`
  start_line = start_line_string.to_i
  if start_line != 0
    # This command returns: `lineNumber:==================` -> `cut` takes care of removing everything except the line number
    end_line_string = `tail -n +#{start_line} #{log_file} | grep -in "==================" | cut -f1 -d:`
    end_line = start_line + (end_line_string.to_i - 1)

    sanitizer_warning = `sed -n '#{(start_line - 1)},#{end_line}p' #{log_file}`

    sanitizer_warning
  end
end
