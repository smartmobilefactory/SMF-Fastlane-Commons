#!/usr/bin/ruby
require 'json'
require 'date'

def smf_meta_report_ios(options)
	# Analysis
	analysis_data = _smf_analyse_ios_project(smf_workspace_dir)
  UI.message("data analysed")

  # Format and prepare data for uploading
  upload_data = _smf_create_meta_report_to_upload(analysis_data)

  # Upload data
  _smf_upload_meta_report_to_spread_sheet(upload_data)

end

def _smf_analyse_ios_project(src_root)
  # TODO: use _smf_unwrap_value() ?

  analysis_json = {}
  UI.message("Fetching data: xcode_version")
  analysis_json[:xcode_version] = smf_analyse_xcode_version()
  UI.message("Fetching data: swiftlint_warnings")
  analysis_json[:swiftlint_warnings] = smf_analyse_swiftlint_warnings()
  UI.message("Fetching data: programming_language")
  analysis_json[:programming_language] = smf_analyse_programming_language()
  UI.message("Fetching data: idfa")
  analysis_json[:idfa] = smf_analyse_idfa()
  UI.message("Fetching data: bitcode")
  analysis_json[:bitcode] = smf_analyse_bitcode()
  UI.message("Fetching data: branch")
  analysis_data[:branch] = options[:branch]
  UI.message("Fetching data: date")
  analysis_data[:date] = Date.today.to_s
  UI.message("Fetching data: repo")
  analysis_data[:repo] = _smf_unwrap_value(@smf_fastlane_config[:project][:project_name])
  UI.message("Fetching data: platform")
  analysis_data[:platform] = _smf_unwrap_value(_smf_meta_report_platform_friendly_name())

  return analysis_json
end

def _smf_create_meta_report_to_upload(project_data)
  UI.message("Preparing data for upload to spreadsheet")

  data_json = smf_create_sheet_data_from_entries(project_data, :META_REPORTING)

  UI.message("DEBUG #{analysis_json}")  #debug

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