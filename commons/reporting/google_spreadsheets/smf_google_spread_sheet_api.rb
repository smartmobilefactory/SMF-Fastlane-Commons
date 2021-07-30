#!/usr/bin/ruby
require 'json'
require 'net/http'
require 'date'

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

  response = Net::HTTP.start(access_token_uri.hostname, access_token_uri.port, use_ssl: true) do |client|
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

def _smf_google_api_start_request(request, uri)
  # First renew the access token
  bearer_token = _smf_google_api_get_bearer_token

  # Delay of 5 seconds to let Google's servers propagate the new access_token
  # https://stackoverflow.com/a/42771170/2790648
  # Added on 14.09.2020 due to random "Internal Server Error (RuntimeError)"
  sleep(5)

  request.content_type = 'application/json'
  request['Accept'] = 'application/json'
  request['Authorization'] = "Bearer #{bearer_token}"

  File.write("debugging_reporting.request", request.pretty_print)

  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |client|
    client.request(request)
  end

  case response
  when Net::HTTPSuccess
    begin
      body = JSON.parse(response.body)
      return body
    rescue
      raise 'Error parsing response body'
    end
  else
    raise "API error: #{response.code}:'#{response.message}' for request: #{uri}\n Body: #{response.body}"
  end
end

# Using a temporary access token, delete all data from a spreadsheet's page
def smf_google_api_delete_data_from_spreadsheet(sheet_id, sheet_name)

  uri = URI.parse"https://sheets.googleapis.com/v4/spreadsheets/#{sheet_id}/values/#{sheet_name}:clear"
  request = Net::HTTP::Post.new(uri)

  _smf_google_api_start_request(request, uri)
end

# Using a temporary access token, upload a CSV string to a spreadsheet's page
def smf_google_api_upload_csv_to_spreadsheet(spreadsheet_id, sheet_id, csv_data)

  uri = URI.parse"https://sheets.googleapis.com/v4/spreadsheets/#{spreadsheet_id}:batchUpdate"
  request = Net::HTTP::Post.new(uri)

  data = {
    "requests": [{
        "pasteData": {
          "coordinate": {
            "sheetId": sheet_id,
            "rowIndex": "0",
            "columnIndex": "0"
          },
          "data": csv_data,
          "type": "PASTE_NORMAL",
          "delimiter": ";",
        }
    }]
  }

  request.body = data.to_json

  _smf_google_api_start_request(request, uri)
end

# Using a temporary access token, get the identifier of a sheet based on its name
def smf_google_api_get_sheet_id_from_spreadsheet(spreadsheet_id, sheet_name)

  uri = URI.parse"https://sheets.googleapis.com/v4/spreadsheets/#{spreadsheet_id}"
  request = Net::HTTP::Get.new(uri)

  response_body = _smf_google_api_start_request(request, uri)
  sheet_id = nil
  response_body.dig('sheets').each do |sheet|
    if sheet.dig('properties', 'title') == sheet_name
      sheet_id = sheet.dig('properties', 'sheetId')
    end
  end

  return sheet_id
end

# Using a temporary access token, append the data to a given online spreadsheet
def smf_google_api_append_data_to_spread_sheet(sheet_id, sheet_name, data)

  uri = URI.parse"https://sheets.googleapis.com/v4/spreadsheets/#{sheet_id}/values/#{sheet_name}:append?valueInputOption=USER_ENTERED"
  request = Net::HTTP::Post.new(uri)
  request.body = data

  _smf_google_api_start_request(request, uri)
end

# Using a temporary access token, get the data from an online spreadsheet
def smf_google_api_get_data_from_spread_sheet(sheet_id, sheet_name)

  uri = URI.parse"https://sheets.googleapis.com/v4/spreadsheets/#{sheet_id}/values/#{sheet_name}"
  request = Net::HTTP::Get.new(uri)

  response_body = _smf_google_api_start_request(request, uri)
  return response_body.dig('values')
end

# Takes sheet_entries (array) and reporting_type to gather the necessary keys
# for a valid JSON reporting to the online spreadsheet.
def smf_create_sheet_data_from_entries(sheet_entries, reporting_type)

  values = []

  sheet_entries.each do |entry|
    if reporting_type == :AUTOMATIC_REPORTING
      values.push(_smf_automatic_reporting_spreadsheet_entry_to_line(entry))
    elsif reporting_type == :APPLE_META_REPORTING
      values.push(_smf_apple_meta_reporting_spreadsheet_entry_to_line(entry))
    elsif reporting_type == :ANDROID_META_REPORTING
      values.push(_smf_android_meta_reporting_spreadsheet_entry_to_line(entry))
    elsif reporting_type == :FINANCIAL_REPORTING
      values.push(_smf_financial_reporting_spreadsheet_entry_to_line(entry))
    end
  end

  data = {
    'values' => values,
    'majorDimension' =>'ROWS'
  }

  data.to_json
end

# A spread sheet entry holds data for one line of the spread sheet
# It is important that for each entry there is a value set.
# If a value does not existent (e.g. nil) it should be set to
# an empty string, to ensure this, use '_smf_unwrap_value'.
def smf_create_spreadsheet_entry(data)
  # The project_name is required.
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

############### SPREAD SHEET HELPER ###############

def _smf_automatic_reporting_spreadsheet_entry_to_line(entry)
  # The order of the elements in this array directly correspond to the table columns in the google spread sheet
  # thus it is VERY IMPORTANT to not change the order!
  [entry[:date], entry[:repo], entry[:branch], entry[:platform], entry[:build_variant], entry[:test_coverage], entry[:covered_lines], entry[:unit_test_count]]
end

def _smf_apple_meta_reporting_spreadsheet_entry_to_line(entry)
  # The order of the elements in this array directly correspond to the table columns in the google spread sheet
  # thus it is VERY IMPORTANT to not change the order!
  [entry[:date], entry[:repo], entry[:platform], entry[:branch], entry[:xcode_version], entry[:idfa], entry[:bitcode], entry[:swiftlint_warnings], entry[:ats], entry[:swift_version], entry[:deployment_target]]
end

def _smf_android_meta_reporting_spreadsheet_entry_to_line(entry)
  # The order of the elements in this array directly correspond to the table columns in the google spread sheet
  # thus it is VERY IMPORTANT to not change the order!
  [entry[:date], entry[:repo], entry[:platform], entry[:branch], entry[:min_sdk_version], entry[:target_sdk_version], entry[:kotlin_version], entry[:gradle_version]]
end

def _smf_financial_reporting_spreadsheet_entry_to_line(entry)
  # The order of the elements in this array directly correspond to the table columns in the google spread sheet
  # thus it is VERY IMPORTANT to not change the order!
  [entry[:date], entry[:project], entry[:sales], entry[:expenses], entry[:target], entry[:actual], entry[:daily_rate]]
end

def _smf_unwrap_value(value)
  value.nil? ? '' : value
end
