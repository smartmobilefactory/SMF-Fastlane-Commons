private_lane :smf_write_changelog do |options|

  sh "rm #{_smf_changelog_temp_path}" if File.exist?(_smf_changelog_temp_path)
  UI.message("Writing changelog temporarily to #{_smf_changelog_temp_path}")
  File.write(_smf_changelog_temp_path, options[:changelog])

  if !options[:html_changelog].nil?
    UI.message("Writing changelog as html to temoprary file #{_smf_changelog_html_temp_path}")
    File.write(_smf_changelog_html_temp_path, options[:html_changelog])
  end

  if !options[:slack_changelog].nil?
    UI.message("Writing changelog as slack_markdown to temoprary file #{_smf_changelog_slack_markdown_temp_path}")
    File.write(_smf_changelog_slack_markdown_temp_path, options[:slack_changelog])
  end
end
