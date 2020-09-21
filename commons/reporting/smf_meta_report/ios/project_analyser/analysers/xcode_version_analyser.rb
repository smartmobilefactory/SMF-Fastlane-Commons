#!/usr/bin/ruby

module XcodeVersion

  # returns a tupel describing the status and what the error is
  # first tupel entry is the status: OK, WARNING, ERROR
  # seconde tupel entry is a message
  def self.verification(src_root)
    return smf_verify_project_property(:xcode_version)
  end

  def self.analyse(src_root)
    UI.message("Analysing #{self.to_s} ...")
    UI.message("DEBUG #{@smf_fastlane_config}")
    return @smf_fastlane_config['project'][:xcode_version]
  end
end