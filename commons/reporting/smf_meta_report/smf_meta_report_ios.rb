#!/usr/bin/ruby
require 'json'
require 'date'

def smf_meta_report_ios(options)
	# Analysis
	analysis_data = _smf_analyse_ios_project(smf_workspace_dir)
  UI.message("data analysed")

  # Upload
  if analysis_data.nil?
    UI.error("Project data is nil, can't report to google sheet")
    raise 'Project data not available'
  else

    analysis_data[:branch] = options[:branch]

    upload_data = _smf_create_meta_report_to_upload(analysis_data)
    _smf_upload_meta_report_to_spread_sheet(upload_data)
  end
end

def _smf_analyse_ios_project(src_root)
  analysis_json = {}
  analysis_json[:xcode_version] = smf_analyse_xcode_version()
  analysis_json[:swiftlint_warnings] = smf_analyse_swiftlint_warnings()
  analysis_json[:programming_language] = smf_analyse_programming_language()
  analysis_json[:idfa] = smf_analyse_idfa()
  analysis_json[:bitcode_enabled] = smf_analyse_bitcode()

  UI.message("DEBUG #{analysis_json}")  #debug
  return analysis_json
end

def _smf_create_meta_report_to_upload(project_data)
  UI.message("Preparing data for upload to spreadsheet")
  meta_data = {
    :date => Date.today.to_s,
    :repo => _smf_unwrap_value(@smf_fastlane_config[:project][:project_name]),
    :platform => _smf_unwrap_value(_smf_meta_report_platform_friendly_name()),
    :branch => _smf_unwrap_value(project_data['branch']),
    :xcode_version => _smf_unwrap_value(project_data['xcode_version']),
    :idfa => _smf_unwrap_value(project_data.dig('idfa', 'usage')),
    :bitcode => _smf_unwrap_value(project_data['bitcode_enabled']),
    :swiftlint_warnings => _smf_unwrap_value(project_data['swiftlint_warnings'])
  }

  data_json = smf_create_sheet_data_from_entries(meta_data, :META_REPORTING)
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