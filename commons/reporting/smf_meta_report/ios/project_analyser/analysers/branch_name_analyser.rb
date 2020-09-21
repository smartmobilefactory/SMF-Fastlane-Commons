#!/usr/bin/ruby

module BranchName

  KEY = 'branch_name'
  BRANCH_MATCH_REGEX = /\*\s(.+)/
  @branch_name = nil
  # returns a tupel describing the status and what the error is
  # first tupel entry is the status: OK, WARNING, ERROR
  # seconde tupel entry is a message
  def self.verification(src_root)
    @branch_name = `if cd #{src_root} 2> /dev/null; then git branch 2> /dev/null; else echo "error"; fi`

    if @branch_name == "error\n"
      return :ERROR, "Error, directory \"#{src_root}\" does not exist. Can't analyse branch name."
    end

    if @branch_name == ""
      return :ERROR, "Error getting branch name with call \"git branch\""
    end

    branch_name_match = @branch_name.match(/\*\s(.+)/)

    if branch_name_match != nil && branch_name_match.captures[0] != nil
      @branch_name = branch_name_match.captures[0]
    else
      return :ERROR, "Error extracting branch name from string \"#{@branch_name}\" with regex \"#{BRANCH_MATCH_REGEX.source}\""
    end

    return :OK
  end

  # returns the analysed property
  def self.analyse(src_root)
    UI.message("Analysing #{self.to_s} ...")
    return @branch_name
  end
end