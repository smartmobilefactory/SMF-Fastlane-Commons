require 'date'

private_lane :smf_android_monitor_unit_tests do |options|

  test_count = 0

  # Change directory to search for test result files
  Dir.chdir(smf_workspace_dir) do
    test_results = Dir.glob('**/build/test-results/**/TEST-*.xml')
    if test_results.empty?
      UI.message("No test result files found in #{smf_workspace_dir}")
    end
    test_results.each do |test_result|
      File.open(test_result,"r") do |file|
        text = file.read
        if test_result_match = text.match("tests=\"([0-9]+)\"")
          test_count += test_result_match.captures[0].to_i
        end
      end
    end
  end

  # Prepare raw data for the spreadsheet entry
  options[:unit_test_count] = test_count
  sheet_entry = smf_create_spreadsheet_entry(options)

  # Gather API credentiels and format data for the API
  sheet_id = ENV[$REPORTING_GOOGLE_SHEETS_UNIT_TESTS_DOC_ID_KEY]
  sheet_name = $REPORTING_GOOGLE_SHEETS_UNIT_TESTS_SHEET_NAME_PLAYGROUND
  sheet_data = smf_create_sheet_data_from_entries([sheet_entry], :AUTOMATIC_REPORTING)

  # Push to monitoring data to Google Spreadsheet via the API
  smf_google_api_append_data_to_spread_sheet(sheet_id, sheet_name, sheet_data)
end
