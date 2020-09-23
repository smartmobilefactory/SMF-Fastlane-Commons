#!/usr/bin/ruby

FILES_TO_IGNORE = ['BITHockeyManager.h', 'create-project-json.sh']
DIR_TO_IGNORE = ['.xcarchive', '.fastlane-smf-commons', 'build']

# returns the analysed property
def smf_analyse_idfa_usage
  src_root = smf_workspace_dir
  UI.message("Analyser: #{__method__.to_s} ...")

  idfa_appearances = []
  file_candidates = []
  file_candidates = `fgrep -R advertisingIdentifier #{src_root} #{_smf_idfa_analyser_ignore_files_string} || echo "disabled"`

  if file_candidates == "disabled\n"
    return "disabled"
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

  idfa_usage = "disabled"
  if idfa_appearances.length > 0
    idfa_usage = "custom"
    idfa_appearances.each do |appearance|
      UI.important("IDFA appearance in: #{appearance}")
    end
  end

  return idfa_usage
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