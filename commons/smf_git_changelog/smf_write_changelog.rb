private_lane :smf_write_changelog do |options|

  _write_changelog_to_disk(
    _smf_changelog_temp_path,
    options[:changelog],
    "Writing changelog as TXT to #{_smf_changelog_temp_path}"
  )

  _write_changelog_to_disk(
    _smf_changelog_html_temp_path,
    options[:html_changelog],
    "Writing changelog as HTML to #{_smf_changelog_html_temp_path}"
  )

  _write_changelog_to_disk(
    _smf_changelog_slack_markdown_temp_path,
    options[:slack_changelog],
    "Writing changelog as Slack Markdown to #{_smf_changelog_html_temp_path}"
  )

  _write_changelog_to_disk(
    _smf_ticket_tags_temp_path,
    options[:ticket_tags],
    "Writing related ticket tags to #{_smf_ticket_tags_temp_path}"
  )
end

def _write_changelog_to_disk(path, content, log)
  if !content.nil?
    UI.message(log)
    sh "rm #{path}" if File.exist?(path)
    File.write(path, content)
  end
end
