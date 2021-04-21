
private_lane :smf_read_changelog do |options|

  case options[:type]
  when :html
    UI.message("Reading changelog from #{_smf_changelog_html_temp_path}")
    result = File.read(_smf_changelog_html_temp_path).to_s
  when :slack_markdown
    UI.message("Reading changelog from #{_smf_changelog_slack_markdown_temp_path}")
    result = File.read(_smf_changelog_slack_markdown_temp_path).to_s
  when :ticket_tags
    UI.message("Reading ticket tags from #{_smf_ticket_tags_temp_path}")
    result = File.read(_smf_ticket_tags_temp_path).to_s.split(' ')
  else
    UI.message("Reading changelog from #{_smf_changelog_temp_path}")
    result =  File.read(_smf_changelog_temp_path).to_s
  end

  result
end
