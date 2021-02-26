#!/usr/bin/ruby

def smf_send_meta_report(project_data, type)

  # Unwrap data: Replace all missing values with empty strings
  unwrapped_data = {}
  project_data.each { |key, value|
    unwrapped_data[key] = _smf_unwrap_value(value)
  }

  # Select sheet in spreadsheet
  sheet_name = ''
  case type
    when :ANDROID_META_REPORTING
      sheet_name = $REPORTING_GOOGLE_SHEETS_META_INFO_SHEET_NAME_ANDROID
    when :APPLE_META_REPORTING
      sheet_name = $REPORTING_GOOGLE_SHEETS_META_INFO_SHEET_NAME_APPLE
    else
      sheet_name = $REPORTING_GOOGLE_SHEETS_META_INFO_SHEET_NAME_PLAYGROUND
    end

  # The function smf_create_sheet_data_from_entries expects an array as 1st argument.
  data_json = smf_create_sheet_data_from_entries([unwrapped_data], type)

  # Retrieve the online Google Spreadsheet identifier
  sheet_id = ENV[$REPORTING_GOOGLE_SHEETS_META_INFO_DOC_ID_KEY]
  UI.message("Uploading data to google spreadsheet name: '#{sheet_name}'")
  puts sheet_id
  puts data_json
  smf_google_api_append_data_to_spread_sheet(sheet_id, sheet_name, data_json)
end
