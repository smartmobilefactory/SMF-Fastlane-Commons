#!/usr/bin/ruby

FILES_TO_IGNORE = ["BITHockeyManager.h", "create-project-json.sh"]
DIR_TO_IGNORE = [".xcarchive", "MetaJSON-Wrapper.app", ".fastlane-smf-commons"]

# returns the analysed property
def smf_analyse_idfa()
  src_root = smf_workspace_dir
  UI.message("Analyser: #{__method__.to_s} ...")

  idfa_usage = "disabled"
  idfa_appearances = []
  file_candidates = []
  file_candidates = `fgrep -R advertisingIdentifier #{src_root} #{_smf_idfa_analyser_ignore_files_string} || echo "error"`

  if file_candidates == "error\n"
    return {"usage" => idfa_usage, "appearances" => idfa_appearances}
  else
    file_candidates = file_candidates.split("\n")
  end

  file_candidates.each do |line|
    matches = line.match(/Binary file (.+)\smatches$/)
    if matches != nil
      occourance = matches.captures[0].gsub("#{src_root}", "")
      if idfa_appearances.include?(occourance) == false
        idfa_appearances.push(occourance)
      end
    else
      matches = line.match(/[^:]+/)
      if matches != nil
        occourance = matches[0].gsub(":", "").gsub("#{src_root}", "").gsub("Binary file ", "")
        if idfa_appearances.include?(occourance) == false
          idfa_appearances.push(occourance)
        end
      end
    end
  end

  if idfa_appearances.length > 0
    idfa_usage = "custom"
    UI.message("IDFA appearances: #{idfa_appearances}")
  end

  return {"usage" => idfa_usage, "appearances" => idfa_appearances}
end

def _smf_idfa_analyser_ignore_files_string
  result = ""
  FILES_TO_IGNORE.each do |file|
    result = result + "--exclude #{file} "
  end

  DIR_TO_IGNORE.each do |dir|
    result = result + "--exclude-dir #{dir} "
  end

  return result
end