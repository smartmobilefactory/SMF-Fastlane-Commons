#!/usr/bin/ruby

require 'json'
require 'date'
require 'net/http'


# TODO: merge constants

require_relative '../../Submodules/SMF-Fastlane-Commons/fastlane/utils/Constants.rb'
require_relative '../../Submodules/SMF-Fastlane-Commons/commons/reporting/smf_ios_push_test_results/smf_google_spread_sheet_api.rb'

require_relative 'file_helper.rb'
require_relative 'project_configuration_reader.rb'

module GoogleSpreadSheetUploader

  def self.report_to_google_sheets(analysis_data, branch, src_root)
    project_analysis = analysis_data.find do |analysis|
      analysis[:file] == :project_json
    end

    swift_lint_analysis = analysis_data.find do |analysis|
      analysis[:file] == :swiftlint_json
    end

    if swift_lint_analysis.nil? || swift_lint_analysis[:content].nil?
      UI.important('Unable to find swiftlint.json to report to google sheet')
    else
      swiftlint_report_path = swift_lint_analysis[:content]
      swiftlint_json_content = FileHelper::file_content(swiftlint_report_path)

      if swiftlint_json_content.nil? || swiftlint_json_content.empty?
        UI.important("swiftlint.json is empty, can't report to google sheets")
      else
        swiftlint_json = JSON.parse(swiftlint_json_content)
        swiftlint_error_count = swiftlint_json.count
      end
    end

    if project_analysis.nil? || project_analysis[:content].nil?
      UI.error("Project data is nil, can't report to google sheet")
      raise 'Project data not available'
    else
      project_data = project_analysis[:content]
      project_data['branch'] = branch
      project_data['swiftlint_warnings'] = swiftlint_error_count

      upload_data = GoogleSpreadSheetUploader::create_data_to_upload(project_data, src_root)
      GoogleSpreadSheetUploader::upload_data_to_spread_sheet(upload_data)
    end
  end

  def self.create_data_to_upload(project_data, src_root)
    UI.message("Preparing data for upload to spreadsheet")
    today = Date.today.to_s
    project_name = _smf_unwrap_value(ProjectConfigurationReader::read_project_property(src_root, 'project_name'))
    platform = _smf_unwrap_value(GoogleSpreadSheetUploader::get_platform(src_root))
    branch = _smf_unwrap_value(project_data['branch'])
    xcode_version = _smf_unwrap_value(project_data['xcode_version'])
    idfa = _smf_unwrap_value(project_data.dig('idfa', 'usage'))
    bitcode = _smf_unwrap_value(project_data['bitcode_enabled'])
    swiftlint_warnings = _smf_unwrap_value(project_data['swiftlint_warnings'])

    # The order of these values corresponds to the columns in the google sheet
    # and should not be changed!
    values = [[today, project_name, platform, branch, xcode_version, idfa, bitcode, swiftlint_warnings]]
    data = {
      'values' => values,
      'majorDimension' =>'ROWS'
    }

    data.to_json
  end

  def self.upload_data_to_spread_sheet(data)
    sheet_id = ENV[Constants::REPORTING_GOOGLE_SPREAD_SHEETS_ID_KEY]
    sheet_name = Constants::REPORTING_GOOGLE_SHEETS_SHEET_NAME

    UI.message("Uploading data to google spreadsheet #{sheet_name}")
    # function from fastlane commons submodule
    smf_google_api_append_data_to_spread_sheet(sheet_id, sheet_name, data)
  end

  def self.get_platform(src_root)
    project_fastfile_content = FileHelper::file_content(File.join(src_root, 'fastlane/Fastfile'))
    scan_result = project_fastfile_content.scan(/@platform\s+=\s+:(.+)/)
    return nil if scan_result.nil? || scan_result.empty?

    case scan_result.first.first.to_s
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