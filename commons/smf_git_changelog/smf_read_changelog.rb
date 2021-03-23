
private_lane :smf_read_changelog do |options|
  changelog = nil
  case options[:type]
  when :html
    UI.message("Reading changelog from #{_smf_changelog_html_temp_path}")
    changelog = File.read(_smf_changelog_html_temp_path).to_s
  when :slack_markdown
    UI.message("Reading changelog from #{_smf_changelog_slack_markdown_temp_path}")
    changelog = File.read(_smf_changelog_slack_markdown_temp_path).to_s
  else
    UI.message("Reading changelog from #{_smf_changelog_temp_path}")
    changelog =  File.read(_smf_changelog_temp_path).to_s
  end

  # return the changelog as string
  changelog
end
