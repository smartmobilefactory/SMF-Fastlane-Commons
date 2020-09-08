require 'date'

private_lane :smf_ios_push_test_results do |options|

  project_name = options[:project_name]
  branch = options[:branch]
  platform = options[:platform]

  sheet_entries = []

  ### 1)
  # Use xcode to generate a json report from the .xcresult
  # Depending on the configuration multiple test results could be available
  # QUESTION FOR THOMAS: is this necessary? Could we limit to one platform?
  # `xcrun xccov view --report --json Test-Example-iOS-2020.08.28_12-02-13-+0200.xcresult`
  # For each result, extract the test coverage (first occurence of 'lineCoverage'): /lineCoverage":([0-9.]+)/
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

    next if line_coverage_scan.nil? || line_coverage_scan.empty?

    entry_data = {
      :branch => branch,
      :platform => platform.to_s,
      :test_coverage => line_coverage_scan.first.first.to_f
    }

    new_entry = _smf_create_spreadsheet_entry(project_name, entry_data)
    sheet_entries.push(new_entry) unless new_entry.nil?
  end

  # 2)
  # Refresh Access Token for the Google API using the dedicated endpoint and credentials available in Jenkins
  # POST:
  # https://accounts.google.com/o/oauth2/token + params
  # Parse the result to get a valid access_token
  # curl -d "client_id=$client_id&client_secret=$client_secret&refresh_token=$refresh_token&grant_type=refresh_token" https://accounts.google.com/o/oauth2/token
  access_token_uri = URI.parse('https://accounts.google.com/o/oauth2/token')
  client_id = ENV[$REPORTING_GOOGLE_SHEETS_CLIENT_ID_KEY]
  client_secret = ENV[$REPORTING_GOOGLE_SHEETS_CLIENT_SECRET_KEY]
  refresh_token = ENV[$REPORTING_GOOGLE_SHEETS_REFRESH_TOKEN_KEY]

  request = Net::HTTP::Post.new(access_token_uri)
  request.set_form_data(
    'client_id' => client_id,
    'client_secret' => client_secret,
    'refresh_token' => refresh_token,
    'grant_type' => 'refresh_token'
  )

  response = Net::HTTP.start(access_token_uri.hostname, access_token_uri.port, use_ssl: true ) do |client|
    client.request(request)
  end

  case response
  when Net::HTTPSuccess
    begin
      body = JSON.parse(response.body)
      bearer_token = body.dig('access_token')
    rescue
      raise 'Error parsing response body'
    end
  else
    UI.message("Error fetching refresh token for google api: #{response.message}")
    raise 'Error fetching refresh token'
  end

  # 3)
  # Using the new access_token,
  # Add the code coverage (as well as some other information) to the Google Sheets
  # POST:
  # https://sheets.googleapis.com/v4/spreadsheets/1QsrW4O-S06i7YGkQ1QGWDsiw17lXqifXzl1xAh89v_4/values/Sheet1!A1:F1:append?valueInputOption=USER_ENTERED
  # {
  #   "values": [
  #     # Date         Repo          Branch   Platform  Test Coverage
  #     ["2020-04-28", "HiDrive_iOS-SyncFramework", "master", "iOS", 41]
  #     ["2020-04-28", "HiDrive_iOS-SyncFramework", "master", "macOS", 41]
  #   ],
  #   "majorDimension": "ROWS"
  # }
  sheet_id = ENV[$REPORTING_GOOGLE_SHEETS_DOC_ID_KEY]
  sheet_name = $REPORTING_GOOGLE_SHEETS_SHEET_NAME
  sheet_uri = URI.parse"https://sheets.googleapis.com/v4/spreadsheets/#{sheet_id}/values/#{sheet_name}:append"

  request = Net::HTTP::Post.new(sheet_uri)
  request.content_type = 'application/json'
  request["Accept"] = 'application/json'
  request['Authorization'] = "Bearer #{bearer_token}"

  UI.message("Token: #{bearer_token}")

  values = []

  sheet_entries.each do |entry|
    values.push(_smf_spreadsheet_entry_to_line(entry))
  end

  data = {
    'values' => values,
    'majorDimension' =>'ROWS'
  }

  request.body = "valueInputOption=USER_ENTERED&#{data.to_json}"

  response = Net::HTTP.start(sheet_uri.hostname, sheet_uri.port, use_ssl: true ) do |client|
    client.request(request)
  end

  UI.message("DEBUG: #{data.to_json}")
  case response
  when Net::HTTPSuccess
    UI.message("Successfully added new data to spread sheet")
  else
    UI.message("Error uploading new data to spreadsheet: #{response.message}")
    raise 'Error uploading new data to spreadsheet'
  end

end

def _smf_spreadsheet_entry_to_line(entry)
  [entry[:date], entry[:repo], entry[:branch], entry[:platform], entry[:test_coverage]]
end

def _smf_create_spreadsheet_entry(repo, data)
  return nil if repo.nil?

  today = Date.today.to_s
  entry = {
    :date => today,
    :repo => repo
  }

  entry[:branch] = _smf_unwrap_value(data[:branch])
  entry[:platform] = _smf_unwrap_value(data[:platform])
  entry[:test_coverage] = _smf_unwrap_value(data[:test_coverage])

  entry
end

def _smf_unwrap_value(value)
  value.nil? ? '' : value
end