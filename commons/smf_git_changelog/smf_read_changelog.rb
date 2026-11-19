
private_lane :smf_read_changelog do |options|

  case options[:type]
  when :html
    UI.message("Reading changelog from #{_smf_changelog_html_temp_path}")
    result = File.read(_smf_changelog_html_temp_path).to_s
  when :slack_markdown
    UI.message("Reading changelog from #{_smf_changelog_slack_markdown_temp_path}")
    result = File.read(_smf_changelog_slack_markdown_temp_path).to_s
  when :commits
    # { lines: [String], commits_by_tag: { tag => [String] } }, or nil before the first write
    # (RWCIT-2132)
    UI.message("Reading changelog commits from #{_smf_changelog_commits_temp_path}")
    result = nil
    if File.exist?(_smf_changelog_commits_temp_path)
      commits = JSON.parse(File.read(_smf_changelog_commits_temp_path))
      result = { lines: commits['lines'] || [], commits_by_tag: commits['commits_by_tag'] || {} }
    end
  when :ticket_tags
    UI.message("Reading ticket tags from #{_smf_ticket_tags_temp_path}")
    result = File.read(_smf_ticket_tags_temp_path).to_s.split(' ')
  else
    UI.message("Reading changelog from #{_smf_changelog_temp_path}")
    result =  File.read(_smf_changelog_temp_path).to_s
  end

  result
end
