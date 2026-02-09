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
    "Writing changelog as Slack Markdown to #{_smf_changelog_slack_markdown_temp_path}"
  )

  _write_changelog_to_disk(
    _smf_ticket_tags_temp_path,
    options[:ticket_tags],
    "Writing related ticket tags to #{_smf_ticket_tags_temp_path}"
  )

  # Store DevOps tickets as JSON (CBENEFIOS-2079)
  devops_tickets = options[:devops_tickets]
  if devops_tickets && !devops_tickets.empty?
    devops_json = JSON.pretty_generate(devops_tickets)
    _write_changelog_to_disk(
      _smf_devops_tickets_temp_path,
      devops_json,
      "Writing DevOps tickets to #{_smf_devops_tickets_temp_path}"
    )
  end
end

def _write_changelog_to_disk(path, content, log)
  if !content.nil?
    UI.message(log)
    sh "rm #{path}" if File.exist?(path)
    File.write(path, content)
  end
end

# Read DevOps tickets from temp file (CBENEFIOS-2079)
# @return [Array<Hash>] Array of DevOps ticket hashes
def smf_read_devops_tickets
  path = _smf_devops_tickets_temp_path
  return [] unless File.exist?(path)

  begin
    JSON.parse(File.read(path), symbolize_names: true)
  rescue JSON::ParserError => e
    UI.error("Failed to parse DevOps tickets JSON: #{e.message}")
    []
  end
end

def _smf_devops_tickets_temp_path
  "#{@fastlane_commons_dir_path}/#{$DEVOPS_TICKETS_TEMP_FILE}"
end
