#!/usr/bin/ruby
require 'date'

def smf_meta_report_ios(options)
	# Analysis
	analysis_data = _smf_analyse_ios_project(options)

  # Format and prepare data for uploading
  upload_data = _smf_create_meta_report_to_upload(analysis_data)

  # Upload data
  _smf_upload_meta_report_to_spread_sheet(upload_data)
end

def _smf_analyse_ios_project(options)
  analysis_json = {}
  analysis_json[:date] = Date.today.to_s
  analysis_json[:repo] = @smf_fastlane_config[:project][:project_name]
  analysis_json[:platform] = _smf_meta_report_platform_friendly_name()
  analysis_json[:branch] = ENV['BRANCH_NAME']
  analysis_json[:xcode_version] = @smf_fastlane_config[:project][:xcode_version]
  analysis_json[:idfa] = smf_analyse_idfa_usage()
  analysis_json[:bitcode] = smf_analyse_bitcode()
  analysis_json[:swiftlint_warnings] = smf_swift_lint_number_of_warnings()
  analysis_json[:ats] = smf_analyse_ats_exception()
  version = smf_analyse_swift_version()
  UI.important("Swift version: '#{version}'")
  analysis_json[:swift_version] = version

  return analysis_json
end

def _smf_create_meta_report_to_upload(project_data)
  unwrapped_data = {}
  UI.message("WRAPPED #{project_data}") #debug
  project_data.each { |key, value|
    unwrapped_data[key] = _smf_unwrap_value(value)
  }

  UI.message("UNWRAPPED #{unwrapped_data}") #debug

  # The function smf_create_sheet_data_from_entries expects an array as 1st argument.
  data_json = smf_create_sheet_data_from_entries([unwrapped_data], :META_REPORTING)

  UI.message("FORMATTED #{data_json}") #debug
  return data_json
end

def _smf_upload_meta_report_to_spread_sheet(data)
  sheet_id = ENV[$REPORTING_GOOGLE_SHEETS_META_INFO_DOC_ID_KEY]

  # Use the 'playground' sheet for testing purposing during development
  # TODO: revert to production sheet
  sheet_name = $REPORTING_GOOGLE_SHEETS_META_INFO_SHEET_NAME_PLAYGROUND
  # sheet_name = ENV[$REPORTING_GOOGLE_SHEETS_META_INFO_SHEET_NAME]

  UI.message("Uploading data to google spreadsheet name: '#{sheet_name}'")
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