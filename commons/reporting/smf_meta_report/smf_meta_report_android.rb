#!/usr/bin/ruby
require 'date'

def smf_meta_report_android(options)
  # Analysis
  analysis_data = _smf_analyse_android_project(options)

  if _should_send_android_report_data(analysis_data)
    # Format and prepare data for uploading
    upload_data = _smf_create_meta_report_to_upload(analysis_data)

    # Upload data
    _smf_upload_meta_report_to_spread_sheet(upload_data)
  end
end

# Returns true only when the :branch value respect the required
# format. The goal is to avoid reports for useless-testing branches.
# Accepted format:
# - 'dev' or 'kmpp': branches strictly named
def _should_send_android_report_data(options)
  if branch.match(/^dev$/) # Android
    return false
  end

  if branch.match(/^kmpp$/) # Android (Eismann - temporary)
    return false
  end

  return false
end

def _smf_analyse_android_project(options)
  analysis_json = {}
  analysis_json[:date] = Date.today.to_s
  analysis_json[:repo] = @smf_fastlane_config[:project][:project_name]
  analysis_json[:platform] = smf_meta_report_platform_friendly_name
  analysis_json[:branch] = ENV['BRANCH_NAME']

  return analysis_json
end

def _smf_create_meta_report_to_upload(project_data)
  unwrapped_data = {}
  project_data.each { |key, value|
    unwrapped_data[key] = _smf_unwrap_value(value)
  }

  # The function smf_create_sheet_data_from_entries expects an array as 1st argument.
  data_json = smf_create_sheet_data_from_entries([unwrapped_data], :META_REPORTING)
  return data_json
end

def _smf_upload_meta_report_to_spread_sheet(data)
  sheet_id = ENV[$REPORTING_GOOGLE_SHEETS_META_INFO_DOC_ID_KEY]
  sheet_name = $REPORTING_GOOGLE_SHEETS_META_INFO_SHEET_NAME

  UI.message("Uploading data to google spreadsheet name: '#{sheet_name}'")
  smf_google_api_append_data_to_spread_sheet(sheet_id, sheet_name, data)
end
