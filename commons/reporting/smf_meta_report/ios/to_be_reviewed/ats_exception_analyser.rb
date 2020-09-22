#!/usr/bin/ruby

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

def smf_analyse_ats_exception()
  src_root = smf_workspace_dir
  UI.message("Analyser: #{__method__.to_s} ...")

  plist_paths = ""
  plist_paths += `find #{src_root} -type f -name "*.plist" #{_smf_ats_exception_ignore_paths_string(src_root)}`

  ats_exceptions = []
  plist_paths.split("\n").each do |plist|
    plist_content = File.read(plist)
    should_be_analysed = false
    DIR_TO_MATCH.each do |regex|
      should_be_analysed = (plist.match(regex) != nil) | should_be_analysed
    end

    if should_be_analysed == true
      relative_path = plist.gsub(src_root, "")
      if plist_content.match(/(<key>NSAllowsArbitraryLoads<\/key>[^\\S]*<true\/>)/) != nil
        UI.important("ATS Disabled in plist at path: #{relative_path}")
        ats_exceptions.push("disabled")
      elsif plist_content.match(/(<key>NSExceptionDomains<\/key>)/) != nil
        UI.important("Custom ATS enabled in plist at path: #{relative_path}")
        ats_exceptions.push("custom")
      else
        ats_exceptions.push("enabled")
      end
    end
  end

  if ats_exceptions.include? "disabled"
    return "disabled"
  elsif ats_exceptions.include? "custom"
    return "custom"
  else
    return "enabled"
  end
end

def _smf_ats_exception_ignore_paths_string(src_root)
  exclude_flags = " -not -path "
  result = ""
  PATHS_TO_IGNORE.each do |path|
    result = result + exclude_flags + "\"#{path}\""
  end

  return result
end