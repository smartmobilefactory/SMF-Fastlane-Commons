#!/usr/bin/ruby
require 'json'
require 'date'

def smf_meta_report_ios(options)
	# Analysis
	analysis_data = _smf_analyse_ios_project(options)
  UI.message("data analysed")

  # Format and prepare data for uploading
  upload_data = _smf_create_meta_report_to_upload(analysis_data)

  # Upload data
  _smf_upload_meta_report_to_spread_sheet(upload_data)

end

def _smf_analyse_ios_project(options)
  analysis_json = {}
  UI.message("Fetching data: xcode_version") #debug
  analysis_json[:xcode_version] = smf_analyse_xcode_version()
  UI.message("Fetching data: swiftlint_warnings") #debug
  analysis_json[:swiftlint_warnings] = smf_analyse_swiftlint_warnings()
  UI.message("Fetching data: programming_language") #debug
  analysis_json[:programming_language] = smf_analyse_programming_language()
  UI.message("Fetching data: idfa") #debug
  analysis_json[:idfa] = smf_analyse_idfa()
  UI.message("Fetching data: bitcode") #debug
  analysis_json[:bitcode] = smf_analyse_bitcode()
  UI.message("Fetching data: branch") #debug
  analysis_json[:branch] = options[:branch]
  UI.message("Fetching data: date") #debug
  analysis_json[:date] = Date.today.to_s
  UI.message("Fetching data: repo") #debug
  analysis_json[:repo] = @smf_fastlane_config[:project][:project_name]
  UI.message("Fetching data: platform") #debug
  analysis_json[:platform] = _smf_meta_report_platform_friendly_name()

  return analysis_json
end

def _smf_create_meta_report_to_upload(project_data)
  UI.message("Preparing data for upload to spreadsheet") #debug
  UI.message("Before unwrap: #{project_data}") #debug

  unwrapped_data = {}
  project_data.each { |key, value|
    unwrapped_data[key] = _smf_unwrap_value(value)
  }

  data_json = smf_create_sheet_data_from_entries(unwrapped_data, :META_REPORTING)
  UI.message("DEBUG #{data_json}") #debug
  return data_json
end

def _smf_upload_meta_report_to_spread_sheet(data)
  sheet_id = ENV[$REPORTING_GOOGLE_SHEETS_META_INFO_DOC_ID_KEY]

  # Use the 'playground' sheet for testing purposing during development
  # TODO: revert to production sheet
  sheet_name = ENV[$REPORTING_GOOGLE_SHEETS_META_INFO_SHEET_NAME_PLAYGROUND]
  # sheet_name = ENV[$REPORTING_GOOGLE_SHEETS_META_INFO_SHEET_NAME]

  UI.message("Uploading data to google spreadsheet '#{sheet_name}'")
  # function from fastlane commons submodule
  smf_google_api_append_data_to_spread_sheet(sheet_id, sheet_name, data)
end

def _smf_meta_report_platform_friendly_name()
  case "#{@platform.to_s}"
  when 'ios'
    return 'iOS'
  when 'ios_framework'
    return 'iOS Framework'
  when 'macos'
    return 'macOS'
  when 'apple'
    return 'Apple'
  when 'android'
    return 'Android'
  when 'flutter'
    return 'Flutter'
  end
end