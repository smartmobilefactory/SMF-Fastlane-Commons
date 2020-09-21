#!/usr/bin/ruby
require 'json'
require 'date'
require 'net/http'

require_relative '../../smf_ios_push_test_results/smf_google_spread_sheet_api.rb'
require_relative 'file_helper.rb'
require_relative 'project_configuration_reader.rb'

module GoogleSpreadSheetUploader

  def self.report_to_google_sheets(analysis_data, options)
    project_analysis = analysis_data.find do |analysis|
      analysis[:file] == :project_json
    end

    if project_analysis.nil? || project_analysis[:content].nil?
      UI.error("Project data is nil, can't report to google sheet")
      raise 'Project data not available'
    else
      project_data = project_analysis[:content]
      project_data['branch'] = options[:branch]

      upload_data = GoogleSpreadSheetUploader::create_data_to_upload(project_data)
      GoogleSpreadSheetUploader::upload_data_to_spread_sheet(upload_data)
    end
  end

  def self.create_data_to_upload(project_data)
    UI.message("Preparing data for upload to spreadsheet")
    today = Date.today.to_s
    project_name = _smf_unwrap_value(ProjectConfigurationReader::read_project_property(smf_workspace_dir, 'project_name'))
    platform = _smf_unwrap_value(GoogleSpreadSheetUploader::get_platform())
    branch = _smf_unwrap_value(project_data['branch'])
    xcode_version = _smf_unwrap_value(project_data['xcode_version'])
    idfa = _smf_unwrap_value(project_data.dig('idfa', 'usage'))
    bitcode = _smf_unwrap_value(project_data['bitcode_enabled'])
    swiftlint_warnings = _smf_unwrap_value(project_data['swiftlint_warnings'])

    # The order of these values corresponds to the columns in the google sheet and should not be changed!
    # TODO: use same logic as in "_smf_spreadsheet_entry_to_line" (with a function)
    values = [[today, project_name, platform, branch, xcode_version, idfa, bitcode, swiftlint_warnings]]
    data = {
      'values' => values,
      'majorDimension' =>'ROWS'
    }

    data.to_json
  end

  def self.upload_data_to_spread_sheet(data)
    sheet_id = ENV[$REPORTING_GOOGLE_SHEETS_META_INFO_DOC_ID_KEY]
    sheet_name = ENV[$REPORTING_GOOGLE_SHEETS_META_INFO_SHEET_NAME]

    UI.message("Uploading data to google spreadsheet #{sheet_name}")
    # function from fastlane commons submodule
    smf_google_api_append_data_to_spread_sheet(sheet_id, sheet_name, data)
  end

  def self.get_platform()
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
end