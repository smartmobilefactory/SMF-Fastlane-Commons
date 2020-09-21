#!/usr/bin/ruby

module BuildNumber

  KEY = 'build_number'
  BUILD_NUMBER_REGEX = /([0-9.]+($|\\n))/
  @build_number = nil

  # returns a tupel describing the status and what the error is
  # first tupel entry is the status: OK, WARNING, ERROR
  # seconde tupel entry is a message
  def self.verification()
    src_root = smf_workspace_dir
    agvtool_what_version = "agvtool what-version"
    agvtool_version_output = `cd #{src_root} 2> /dev/null && #{agvtool_what_version} 2> /dev/null`

    if (agvtool_version_output == nil || agvtool_version_output == "")
      return :WARNING, "Error executing \"#{agvtool_what_version}\" to get build number"
    end

    found_build_numbers = []

    agvtool_version_output.split("\n").each do |line|
      if line.match(BUILD_NUMBER_REGEX) != nil
        if found_build_numbers.include?(line.match(BUILD_NUMBER_REGEX)) == false
          found_build_numbers.push(line.match(BUILD_NUMBER_REGEX))
        end
      end
    end

    if found_build_numbers.length == 0
      return :WARNING, "Error, couldn't find a build number in the output of \"#{agvtool_what_version}\""
    end

    if found_build_numbers.length > 1
      return :WARNING, "Warning, there are multiple build numbers in the output of \"#{agvtool_what_version}\": #{found_build_numbers.to_s}"
    end

    @build_number = found_build_numbers[0]
    return :OK
  end

  # returns the analysed property
  def self.analyse()
    UI.message("Analysing #{self.to_s} ...")
    return @build_number
  end
end