require 'net/http'

# Retrieves a temporary access token to the google spread sheets
# use to then upload/add/append new data to google spread sheets
def _smf_google_api_get_bearer_token
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
      return body.dig('access_token')
    rescue
      raise 'Error parsing response body'
    end
  else
    raise "Error fetching refresh token #{response.message}"
  end
end

def smf_google_api_append_data_to_spread_sheet(sheet_id, sheet_name, data)
  bearer_token = _smf_google_api_get_bearer_token

  # Delay of 5 seconds to let Google's servers propagate the new access_token
  # https://stackoverflow.com/a/42771170/2790648
  # Added on 14.09.2020 due to random "Internal Server Error (RuntimeError)"
  sleep(5)

  sheet_uri = URI.parse"https://sheets.googleapis.com/v4/spreadsheets/#{sheet_id}/values/#{sheet_name}:append?valueInputOption=USER_ENTERED"

  request = Net::HTTP::Post.new(sheet_uri)
  request.content_type = 'application/json'
  request['Accept'] = 'application/json'
  request['Authorization'] = "Bearer #{bearer_token}"

  request.body = data

  response = Net::HTTP.start(sheet_uri.hostname, sheet_uri.port, use_ssl: true ) do |client|
    client.request(request)
  end

  unless response.is_a?(Net::HTTPSuccess)
    raise "Error uploading new data to spreadsheet #{response.message}"
  end
end

# Takes sheet_id, sheet_name and sheet_entries to append to the given sheet
# for the structure and necessary keys of a sheet_entry see 'smf_create_spreadsheet_entry(...)'
def smf_create_sheet_data_from_entries(sheet_entries)

  values = []

  sheet_entries.each do |entry|
    values.push(_smf_spreadsheet_entry_to_line(entry))
  end

  data = {
    'values' => values,
    'majorDimension' =>'ROWS'
  }

  data.to_json
end

############### SPREAD SHEET HELPER ###############

def _smf_spreadsheet_entry_to_line(entry)
  # The order of the elements in this array directly correspond to the table columns in the google spread sheet
  # thus it is VERY IMPORTANT to not change the order!
  [entry[:date], entry[:repo], entry[:branch], entry[:platform], entry[:build_variant], entry[:test_coverage], entry[:covered_lines]]
end

# a spread sheet entry holds data for one line of the spread sheet
# it is important that for each entry there is a value set
# so if the a value is not existent (e.g. nil) it should be set to
# an empty string, to ensure this, use '_smf_unwrap_value'
def smf_create_spreadsheet_entry(repo, data)
  return nil if repo.nil?

  today = Date.today.to_s
  entry = {
    :date => today,
    :repo => repo
  }

  entry[:build_variant] = _smf_unwrap_value(data[:build_variant])
  entry[:branch] = _smf_unwrap_value(data[:branch])
  entry[:platform] = _smf_unwrap_value(data[:platform])
  entry[:test_coverage] = _smf_unwrap_value(data[:test_coverage])
  entry[:covered_lines] = _smf_unwrap_value(data[:covered_lines])

  entry
end

def _smf_unwrap_value(value)
  value.nil? ? '' : value
end