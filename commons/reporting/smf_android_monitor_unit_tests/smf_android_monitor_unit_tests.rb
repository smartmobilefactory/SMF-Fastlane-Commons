require 'date'

private_lane :smf_android_monitor_unit_tests do |options|

  project_dir = smf_workspace_dir
  # unless Dir.exist?(project_dir)
  #   UI.messsage("The directory '#{project_dir}' does not exist")
  #   raise 'Missing test result directory'
  # end

  # Change directory to search for test result files
  Dir.chdir(project_dir)

  test_results = Dir.glob('**/build/test-results/**/TEST-*.xml')
  if test_results.empty?
    UI.message("No test result files found in #{project_dir}")
  end

  test_count = 0
  test_results.each do |test_result|
    File.open(test_result,"r") do |file|
      text = file.read
      if test_result_match = text.match("tests=\"([0-9]+)\"")
        test_count += test_result_match.captures[0].to_i
      end
    end
  end

  UI.message("test count: #{test_count}")

  options[:unit_test_count] = test_count

  sheet_entry = smf_create_spreadsheet_entry(options)

  UI.message("new entry: #{sheet_entry}")

  sheet_id = ENV[$REPORTING_GOOGLE_SHEETS_UNIT_TESTS_DOC_ID_KEY]
  sheet_name = $REPORTING_GOOGLE_SHEETS_UNIT_TESTS_SHEET_NAME_PLAYGROUND
  sheet_data = smf_create_sheet_data_from_entries(sheet_entry, :AUTOMATIC_REPORTING)
  puts sheet_data
  # smf_google_api_append_data_to_spread_sheet(sheet_id, sheet_name, sheet_data)
end

# a spread sheet entry holds data for one line of the spread sheet
# it is important that for each entry there is a value set
# so if the a value is not existent (e.g. nil) it should be set to
# an empty string, to ensure this, use '_smf_unwrap_value'
def smf_create_spreadsheet_entry(data)
  return nil if data[:project_name].nil?

  entry = {
    :date => Date.today.to_s,
    :repo => data[:project_name],
    :build_variant => _smf_unwrap_value(data[:build_variant]),
    :branch => _smf_unwrap_value(data[:branch]),
    :platform => _smf_unwrap_value(data[:platform]),
    :test_coverage => _smf_unwrap_value(data[:test_coverage]),
    :covered_lines => _smf_unwrap_value(data[:covered_lines]),
    :unit_test_count => _smf_unwrap_value(data[:unit_test_count])
  }

  entry
end

# def _smf_unwrap_value(value)
#   value.nil? ? '' : value
# end

# options = {:branch => 'dev', :project_name => "eismann"}
# smf_android_monitor_unit_tests(options, "/Users/kevindelord/Downloads/Eismann")

