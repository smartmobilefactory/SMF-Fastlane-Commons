#!/usr/bin/ruby

# Import modules which analyse one specific property each
require_relative './analysers/xcode_version_analyser.rb'
require_relative './analysers/programming_language_version_analyser.rb'
require_relative './analysers/programming_language_analyser.rb'
require_relative './analysers/bitcode_usage_analyser.rb'
require_relative './analysers/build_number_analyser.rb'
require_relative './analysers/marketing_version_analyser.rb'
require_relative './analysers/idfa_analyser.rb'
# require_relative './analysers/ats_exception_analyser.rb'
require_relative './analysers/swiftlint_analyser.rb'

module IOSProjectAnalyser

  ANALYSERS = [
    XcodeVersion,
    ProgrammingLanguageVersion,
    ProgrammingLanguage,
    BitcodeUsage,
    BuildNumber,
    Idfa,
    # AtsException, (currently disabled - logic must be reviewed)
    SwiftlintAnalyser
  ]

  def self.log_status(status, msg)
    if status == :ERROR
      UI.error("[#{status.to_s}] #{msg}")
    elsif status == :WARNING
      UI.important("[#{status.to_s}] #{msg}")
    elsif msg != nil
      UI.message("[#{status.to_s}] #{msg}")
    end
  end

  # verify all analysers
  def self.validate(src_root)
    UI.message("Verifying #{self.to_s}s")
    verified_analysers = []
    fatal_errors = false

    UI.message("looping on #{ANALYSERS}")
    for analyser in ANALYSERS
      UI.message("analysing analyser: #{analyser.to_s}")
      status, message = analyser.verification(src_root)
      if status == :OK
        UI.message("ok! for analyser #{analyser.to_s}")
        verified_analysers.push(analyser)
      elsif status == :ERROR
        UI.message("fatal error for analyser: #{analyser.to_s}")
        fatal_errors = true
      end

      if message != nil
        message = "[#{analyser.to_s}] " + message
        UI.message(message)
      end

      IOSProjectAnalyser::log_status(status, message)
    end

    if fatal_errors
      raise "Not all analysers could be verified, stopping analysis..."
    end

    return verified_analysers
  end

  def self.analyse(src_root)
    verified_analysers = validate(src_root)
    UI.message("verified analysers: #{verified_analysers}")
    # Dictionary to hold the final json data which will be pushed to the monitoring tool.
    analysis_json = {}

    # execute all analysers
    UI.message("Starting analysis")
    for analyser in verified_analysers
      analysis_json[analyser::KEY] = analyser.analyse(src_root)
    end

    return { :content => analysis_json }
  end
end

def smf_verify_project_property(property)
    if @smf_fastlane_config[:project][property] == nil
      return :WARNING, "Error reading property \"#{property}\" in projects Config.json"
    end

    return :OK
  end