#!/usr/bin/ruby

module AtsException

  KEY = 'ats'
  PATHS_TO_IGNORE = [
    "*/Pods/*",
    "*/Carthage/*",
    "**/.xcarchive.xcarchive/*",
    "*/MetaJSON-Wrapper.app/*"
  ]

  DIR_TO_MATCH = [
    /.*\/Extensions\/.*/,
    /.*\/PLists\/.*/,
    /.*\/plists\/.*/
  ]

  # returns a tupel describing the status and what the error is
  # first tupel entry is the status: OK, WARNING, ERROR
  # seconde tupel entry is a message
  def self.verification(src_root)
    if File.exist?(src_root) == false
      return :ERROR, "Error the projects root directory (\"#{src_root}\") does not exist"
    end

    return :OK
  end

  # returns the analysed property
  def self.analyse(src_root)
    UI.message("Analysing #{self.to_s} ...")

    plist_paths = ""

    plist_paths += `find #{src_root} -type f -name "*.plist" #{self.ignore_paths_string(src_root)}`

    ats_exceptions = []

    plist_paths.split("\n").each do |plist|
      plist_content = File.read(plist)
      should_be_analysed = false
      DIR_TO_MATCH.each do |regex|
        should_be_analysed = (plist.match(regex) != nil) | should_be_analysed
      end

      if should_be_analysed == true
        if plist_content.match(/(<key>NSAllowsArbitraryLoads<\/key>[^\\S]*<true\/>)/) != nil
          ats_exceptions.push({"level" => "disabled", "plist" => "#{plist.gsub(src_root, "")}"})
        elsif plist_content.match(/(<key>NSExceptionDomains<\/key>)/) != nil
          ats_exceptions.push({"level" => "custom", "plist" => "#{plist.gsub(src_root, "")}"})
        else
          ats_exceptions.push({"level" => "enabled", "plist" => "#{plist.gsub(src_root, "")}"})
        end
      end
    end

    return ats_exceptions
  end

  def self.ignore_paths_string(src_root)
    exclude_flags = " -not -path "
    result = ""
    PATHS_TO_IGNORE.each do |path|
      result = result + exclude_flags + "\"#{path}\""
    end

    return result
  end
end