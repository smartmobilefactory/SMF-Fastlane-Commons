require 'date'

private_lane :smf_ios_monitor_unit_tests do |options|

  project_name = options[:project_name]
  branch = options[:branch]
  platform = options[:platform]
  build_variant = options[:build_variant]

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

  xcresult_file_names.each do |filename|
    json_result_string = `xcrun xccov view --report --json #{File.join(xcresult_dir, filename)}`
    result_parsed = JSON.parse(json_result_string)
    line_coverage = result_parsed.dig('lineCoverage')
    lines_of_code = result_parsed.dig('coveredLines')

    entry_data = {
      :branch => branch,
      :platform => platform.to_s,
      :build_variant => build_variant.to_s
    }

    entry_data[:test_coverage] = line_coverage
    entry_data[:covered_lines] = lines_of_code

    new_entry = smf_create_spreadsheet_entry(project_name, entry_data)
    sheet_entries.push(new_entry) unless new_entry.nil?
  end

  sheet_id = ENV[$REPORTING_GOOGLE_SHEETS_UNIT_TESTS_DOC_ID_KEY]
  sheet_name = $REPORTING_GOOGLE_SHEETS_UNIT_TESTS_SHEET_NAME

  sheet_data = smf_create_sheet_data_from_entries(sheet_entries)
  smf_google_api_append_data_to_spread_sheet(sheet_id, sheet_name, sheet_data)
end