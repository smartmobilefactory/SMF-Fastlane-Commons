private_lane :smf_ios_push_test_results do |options|

  project_name = options[:project_name]
  branch = options[:branch]
  platform = options[:platform]

  UI.important("Upcoming feature...")
  ### 1)
  # Use xcode to generate a json report from the .xcresult
  # Depending on the configuration multiple test results could be available
  # QUESTION FOR THOMAS: is this necessary? Could we limit to one platform?
  # `xcrun xccov view --report --json Test-Example-iOS-2020.08.28_12-02-13-+0200.xcresult`
  # For each result, extract the test coverage (first occurence of 'lineCoverage'): /lineCoverage":([0-9.]+)/

  # 2)
  # Refresh Access Token for the Google API using the dedicated endpoint and credentials available in Jenkins
  # POST:
  # https://accounts.google.com/o/oauth2/token + params
  # Parse the result to get a valid access_token
  # curl -d "client_id=$client_id&client_secret=$client_secret&refresh_token=$refresh_token&grant_type=refresh_token" https://accounts.google.com/o/oauth2/token

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
end
