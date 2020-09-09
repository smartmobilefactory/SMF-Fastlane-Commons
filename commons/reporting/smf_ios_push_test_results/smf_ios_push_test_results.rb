require 'date'

private_lane :smf_ios_push_test_results do |options|
  # set slack channel to reporting error log channel
  smf_switch_to_reporting_slack_channel

  project_name = options[:project_name]
  branch = options[:branch]
  platform = options[:platform]

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
    line_coverage_scan = json_result_string.scan(/lineCoverage":([0-9.]+)/)
    lines_of_code_scan = json_result_string.scan(/coveredLines":([0-9]+)/)

    entry_data = {
      :branch => branch,
      :platform => platform.to_s
    }

    unless line_coverage_scan.nil? || line_coverage_scan.empty?
      entry_data[:test_coverage] = line_coverage_scan.first.first.to_f
    end

    unless lines_of_code_scan.nil? || lines_of_code_scan.empty?
      entry_data[:covered_lines] = lines_of_code_scan.first.first.to_i
    end

    new_entry = smf_create_spreadsheet_entry(project_name, entry_data)
    sheet_entries.push(new_entry) unless new_entry.nil?
  end

  sheet_id = ENV[$REPORTING_GOOGLE_SHEETS_DOC_ID_KEY]
  sheet_name = $REPORTING_GOOGLE_SHEETS_SHEET_NAME

  smf_google_api_append_data_to_spread_sheet(
    sheet_id,
    sheet_name,
    sheet_entries
  )

  # switch slack channel back to original one
  smf_switch_to_original_slack_channel
end