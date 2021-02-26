#!/usr/bin/ruby
require 'date'

def smf_meta_report_android(options)
  # Analysis
  analysis_data = _smf_analyse_android_project(options)

  if _should_send_android_report_data(analysis_data)
    # Format and upload data to Google Spreadsheet
    smf_send_meta_report(analysis_data, :ANDROID_META_REPORTING)
  else
    puts "Meta Reporting disabled for branch: '#{analysis_data[:branch]}'"
  end
end

# Returns true only when the :branch value respect the required
# format. The goal is to avoid reports for useless-testing branches.
# Accepted strictly named branches: 'master', 'dev' or 'kmpp'
def _should_send_android_report_data(options)
  puts "Branch should be: '#{ENV['BRANCH_NAME']}' and is '#{options[:branch]}'"
  if options[:branch].match(/^master$/)
    return true
  end

  if options[:branch].match(/^dev$/) # Android
    return true
  end

  if options[:branch].match(/^kmpp$/) # Android (Eismann - temporary)
    return true
  end

  if options[:branch].match(/^reporting$/) # Android (Eismann - temporary)
    return true
  end

  return false
end

def _smf_analyse_android_project(options)
  puts options

  analysis_json = {}
  analysis_json[:date] = Date.today.to_s
  analysis_json[:repo] = @smf_fastlane_config[:project][:project_name]
  analysis_json[:platform] = smf_meta_report_platform_friendly_name
  analysis_json[:branch] = ENV['BRANCH_NAME']

  report = smf_project_report_android
  analysis_json[:kotlin_version] = report['kotlinVersion'].to_s
  analysis_json[:gradle_version] = report['gradleVersion'].to_s
  analysis_json[:target_sdk_version] = report['targetSdkVersion'].to_s
  analysis_json[:min_sdk_version] = report['minSdkVersion'].to_s

  puts analysis_json
  return analysis_json
end
