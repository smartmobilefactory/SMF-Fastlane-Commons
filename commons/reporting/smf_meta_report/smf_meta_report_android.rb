#!/usr/bin/ruby
require 'date'

def smf_meta_report_android(options)
  # Analysis
  analysis_data = _smf_analyse_android_project(options)

  if _should_send_android_report_data(analysis_data)
        # Format and upload data to Google Spreadsheet
    smf_send_meta_report(analysis_data, :ANDROID_META_REPORTING)
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
