#!/usr/bin/ruby
require 'date'
require 'json'

def smf_meta_report_ios(options)
  # Analysis
  analysis_data = _smf_analyse_ios_project(options)

  if _should_send_report_data(analysis_data)
    # Format and prepare data for uploading
    upload_data = _smf_create_meta_report_to_upload(analysis_data)

    # Upload data
    _smf_upload_meta_report_to_spread_sheet(upload_data)
  end
end

# Returns true only when the :branch value respect the required
# format. The goal is to avoid reports for useless-testing branches.
# Accepted format:
# - 'master': branch strictly named master
# - '<version>/master': where version is only digit with optional 'decimal'
#      examples: '12/master', '3.4/master'
def _should_send_report_data(options)
  if options[:branch].match(/^master$/)
    return true
  end

  if options[:branch].match(/^\d+\.?\d*\/master$/)
    return true
  end

  return false
end

def _smf_analyse_ios_project(options)
  xcode_settings = smf_xcodeproj_settings(options)

  analysis_json = {}
  analysis_json[:date] = Date.today.to_s
  analysis_json[:repo] = @smf_fastlane_config[:project][:project_name]
  analysis_json[:platform] = smf_meta_report_platform_friendly_name
  analysis_json[:branch] = ENV['BRANCH_NAME']
  analysis_json[:xcode_version] = @smf_fastlane_config[:project][:xcode_version]
  analysis_json[:idfa] = smf_analyse_idfa_usage
  analysis_json[:bitcode] = smf_analyse_bitcode(xcode_settings, options)
  analysis_json[:swiftlint_warnings] = smf_swift_lint_number_of_warnings
  analysis_json[:ats] = smf_analyse_ats_exception
  analysis_json[:swift_version] = smf_analyse_swift_version(xcode_settings, options)
  analysis_json[:deployment_target] = smf_analyse_deployment_target(xcode_settings, options)

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
