#!/usr/bin/ruby

require_relative '../../../helper/logger.rb'

module MarketingVersion

  KEY = 'build_number'
  MARKETING_VERSION_REGEX = /(CFBundleShortVersionString of \"([^\"]+)\")/
  @marketing_version = nil

  # returns a tupel describing the status and what the error is
  # first tupel entry is the status: OK, WARNING, ERROR
  # seconde tupel entry is a message
  def self.verification(src_root)
    agvtool_what_marketing = "agvtool what-marketing-version"
    agvtool_marketing_output = `cd #{src_root} 2> /dev/null && #{agvtool_what_marketing} 2> /dev/null`

    if (agvtool_marketing_output == nil || agvtool_marketing_output == "")
      return :WARNING, "Error executing \"#{agvtool_what_marketing}\" to get marketing version"
    end

    marketing_versions = []

    agvtool_marketing_output.split("\n").each do |line|
      regex_match = line.match(MARKETING_VERSION_REGEX)
      if regex_match != nil
        if marketing_versions.include?(regex_match.captures[1]) == false
          marketing_versions.push(regex_match.captures[1])
        end
      end
    end

    if marketing_versions.length == 0
      return :WARNING, "Error, couldn't find a marketing version in the output of \"#{agvtool_what_marketing}\""
    end

    if marketing_versions.length > 1
      return :WARNING, "Warning, there are multiple marketing versions in the output of \"#{agvtool_what_marketing}\": \n #{marketing_versions.to_s}"
    end

    @marketing_version = marketing_versions[0]
    return :OK
  end

  # returns the analysed property
  def self.analyse(src_root)
    Logger::info("Analysing #{self.to_s} ...")
    return @marketing_version
  end
end