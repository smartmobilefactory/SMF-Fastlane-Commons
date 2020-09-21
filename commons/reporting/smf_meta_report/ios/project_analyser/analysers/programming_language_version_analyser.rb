#!/usr/bin/ruby

module ProgrammingLanguageVersion

  KEY = 'programming_language_version'

  def self.verification(src_root)
    return smf_verify_project_property(:programming_language_version)
  end

  def self.analyse(src_root)
    UI.message("Analysing #{self.to_s} ...")
    return @smf_fastlane_config[:project][:programming_language_version]
  end
end