#!/usr/bin/ruby
require 'date'

def smf_meta_report_ios(options)
  # Analysis
  analysis_data = _smf_analyse_ios_project(options)

  if _should_send_ios_report_data(analysis_data)
    # Meta reporting to Google Sheets is disabled
    smf_send_meta_report(analysis_data, :APPLE_META_REPORTING)
  else
    puts "Meta Reporting disabled for branch: '#{analysis_data[:branch]}'"
  end
end

# Returns true only when the :branch value respect the required
# format. The goal is to avoid reports for useless-testing branches.
# Accepted format:
# - 'master': branch strictly named master
# - '<version>/master': where version is only digit with optional 'decimal'
#      examples: '12/master', '3.4/master'
def _should_send_ios_report_data(options)
  if options[:branch].match(/^master$/) # iOS (A-Team)
    return true
  end

  if options[:branch].match(/^\d+[\d\.]*\/master$/) # iOS (Strato-Team)
    return true
  end

  return false
end

def _smf_analyse_ios_project(options)
  analysis_json = {}
  analysis_json[:date] = Date.today.to_s
  analysis_json[:repo] = @smf_fastlane_config[:project][:project_name]
  analysis_json[:platform] = smf_meta_report_platform_friendly_name
  analysis_json[:branch] = ENV['BRANCH_NAME']
  analysis_json[:xcode_version] = @smf_fastlane_config[:project][:xcode_version]
  analysis_json[:idfa] = smf_analyse_idfa_usage
  analysis_json[:swiftlint_warnings] = smf_swift_lint_number_of_warnings
  analysis_json[:ats] = smf_analyse_ats_exception
  analysis_json[:build_number] = smf_meta_report_build_number_and_version(options[:build_variant])
  # Pod analysis
  analysis_json[:appcenter_crashes] = nil  # AppCenter discontinued
  analysis_json[:sentry] = smf_analyse_sentry_usage
  analysis_json[:qakit] = smf_analyse_qakit_usage
  analysis_json[:debug_menu] = smf_analyse_debug_menu_usage

  # Analysers that are also used by Danger to add warnings to the PR checks
  xcode_settings = smf_xcodeproj_settings(options)
  analysis_json[:bitcode] = smf_analyse_bitcode(xcode_settings, options)
  analysis_json[:swift_version] = smf_analyse_swift_version(xcode_settings, options)
  analysis_json[:deployment_target] = smf_analyse_deployment_targets(xcode_settings, options)

  return analysis_json
end
