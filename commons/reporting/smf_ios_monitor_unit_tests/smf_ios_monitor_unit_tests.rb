require 'date'

private_lane :smf_ios_monitor_unit_tests do |options|

  project_name = @smf_fastlane_config.dig(:project, :project_name)
  build_variant = !options[:build_variant].nil? ? options[:build_variant] : smf_get_first_variant_from_config
  branch = !options[:branch_name].nil? ? options[:branch_name] : smf_workspace_dir_git_branch
  platform = smf_meta_report_platform_friendly_name

  # Platform friendly name
  #
  # build_variant_config = @smf_fastlane_config.dig(:build_variants, build_variant.to_sym)
  # platform = build_variant_config.dig(:platform)
  # if platform.nil?
  #   platform = 'iOS'
  # elsif platform.include?('mac')
  #   platform = 'macOS'
  # end

  # project_name = options[:project_name]
  # branch = options[:branch]
  # platform = options[:platform]
  # build_variant = options[:build_variant]

  sheet_entries = []

  xcresult_dir = File.join(smf_workspace_dir, $XCRESULT_DIR)

  unless Dir.exist?(xcresult_dir)
    UI.messsage("The test result dir: #{xcresult_dir}, does not exist")
    raise 'Missing test result directory'
  end

  xcresult_file_names = Dir.entries(xcresult_dir).select do |file|
    file.to_s.end_with?('.xcresult')
  end

  if xcresult_file_names.empty?
    UI.message("No .xcresult files found in #{xcresult_dir}")
    next
  end

  # Only use one test coverage report
  filename = xcresult_file_names.first
  json_result_string = `xcrun xccov view --report --json #{File.join(xcresult_dir, filename)}`
  result_parsed = JSON.parse(json_result_string)

  entry_data = {
    :project_name => project_name,
    :branch => branch,
    :platform => platform.to_s,
    :build_variant => build_variant.to_s,
    :test_coverage => result_parsed.dig('lineCoverage'),
    :covered_lines => result_parsed.dig('coveredLines')
  }

  # Prepare raw data for the spreadsheet entry
  new_entry = smf_create_spreadsheet_entry(entry_data)
  sheet_entries.push(new_entry) unless new_entry.nil?

  # Gather API credentiels and format data for the API
  sheet_id = ENV[$REPORTING_GOOGLE_SHEETS_UNIT_TESTS_DOC_ID_KEY]
  sheet_name = $REPORTING_GOOGLE_SHEETS_UNIT_TESTS_SHEET_NAME
  sheet_data = smf_create_sheet_data_from_entries(sheet_entries, :AUTOMATIC_REPORTING)

  # Push to monitoring data to Google Spreadsheet via the API
  smf_google_api_append_data_to_spread_sheet(sheet_id, sheet_name, sheet_data)
end
