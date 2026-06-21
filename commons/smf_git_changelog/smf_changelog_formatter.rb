# Aggregated changelog formatter (CBENEFIOS-2508).
#
# One bullet per ticket id. Each ticket bullet shows the Jira title
# (which already includes any cross-org APP-XXXX reference). Commits
# that reference the ticket appear underneath as indented sub-bullets,
# dropped if they duplicate the title.
#
# Commits without a recognised ticket reference are collected at the
# bottom under "Sonstige Änderungen:" (Q1a in CBENEFIOS-2508 design).
# Unknown ticket tags (CBENEFIOS-XXXX without Jira data, APP-only refs
# from sosimple → corporate-benefits, etc.) are dropped entirely (Q2a).
#
# Format-aware:
#   markdown        plain text, NO Jira links (sosimple URLs are unreachable
#                   for CB-side testers — empirically confirmed in real
#                   Firebase tester mails after the afmcli migration)
#   html            full Jira hyperlinks via <a>, nested <ul> for sub-bullets
#   slack_markdown  Slack <url|text> link form
#
# The function signature stays the same so all three callers
# (smf_git_changelog.rb writing the .txt/.html/.slack files, smf_danger.rb
# for danger output) keep working.

FORMAT_ELEMENTS = {
  html: {
    primary_bullet: { prefix: '<li>', postfix: '</li>' },
    sub_bullet:     { prefix: '<li>', postfix: '</li>' },
    list_open:      '<ul>',
    list_close:     '</ul>',
    section_header: { prefix: '<h4>', postfix: '</h4>' },
    link_style:     :html,
    sub_list_break: '<br>'
  },
  markdown: {
    primary_bullet: { prefix: '- ', postfix: "\n" },
    sub_bullet:     { prefix: '  · ', postfix: "\n" },
    list_open:      '',
    list_close:     '',
    section_header: { prefix: "\n", postfix: ":\n\n" },
    link_style:     :none, # NO links — Firebase tester mails can't reach sosimple
    sub_list_break: ''
  },
  slack_markdown: {
    primary_bullet: { prefix: '• ', postfix: "\n" },
    sub_bullet:     { prefix: '   ◦ ', postfix: "\n" },
    list_open:      '',
    list_close:     '',
    section_header: { prefix: "\n*", postfix: ":*\n\n" },
    link_style:     :slack,
    sub_list_break: ''
  }
}.freeze

# ---------------------------------------------------------------------------
# Public entry point — same signature as before, new output.
# ---------------------------------------------------------------------------

def _smf_generate_changelog(changelog, tickets, changelog_format)
  # Normalise inputs. A nil changelog is a legitimate call shape used by
  # smf_danger.rb to ask for just the ticket summary — treat it as no
  # commits and continue, rather than returning ''. Tickets still render.
  changelog_lines = if changelog.nil?
                      []
                    elsif changelog.is_a?(Array)
                      changelog
                    else
                      [changelog.to_s]
                    end
  tickets ||= {}
  normal_tickets = (tickets[:normal] || []).dup
  fmt = FORMAT_ELEMENTS[changelog_format]
  return '' if fmt.nil?
  return '' if normal_tickets.empty? && changelog_lines.empty?

  # Per-tag commit map built locally via PURE regex matching.
  # We intentionally do not call smf_get_ticket_tags_with_commits_from_changelog
  # here — that helper performs a GitHub API call per merge commit
  # (_smf_find_ticket_tags_in_related_pr) which we want to avoid during
  # formatter execution. Pure regex on the commit line is sufficient for
  # attribution; merge commits without a Jira tag in the title fall through
  # to the orphan section.
  commits_by_tag = _smf_build_commits_by_tag(changelog_lines)

  # Sort tickets by tag for deterministic output.
  normal_tickets.sort_by! { |t| t[:tag].to_s }

  output_parts = []
  output_parts << fmt[:list_open] unless fmt[:list_open].empty?

  normal_tickets.each do |ticket|
    output_parts << _smf_render_ticket_block(ticket, commits_by_tag[ticket[:tag]], fmt)
  end

  output_parts << fmt[:list_close] unless fmt[:list_close].empty?

  # Orphan commits — those without any recognised ticket tag.
  orphans = _smf_orphan_commits(changelog_lines)
  if orphans.any?
    output_parts << _smf_render_section_header('Sonstige Änderungen', fmt)
    output_parts << fmt[:list_open] unless fmt[:list_open].empty?
    orphans.each { |line| output_parts << _smf_render_orphan_line(line, fmt) }
    output_parts << fmt[:list_close] unless fmt[:list_close].empty?
  end

  output_parts.join.strip
end

# Build { tag => [cleaned_commit_msg, ...] } map without any network calls.
# Mirrors the regex/cleanup logic of smf_get_ticket_tags_with_commits_from_changelog
# but skips the per-commit GitHub round-trip.
def _smf_build_commits_by_tag(changelog_lines)
  map = {}
  changelog_lines.each do |line|
    next if line.nil? || line.strip.empty?

    tags = _smf_find_ticket_tags_in(line)
    next if tags.empty?

    cleaned = line
      .sub(/\A-\s*/, '')
      .strip

    tags.uniq.each do |tag|
      stripped = cleaned
        .sub(/#{Regexp.escape(tag)}\s*[:\-]?\s*/i, '')
        .sub(/\A\s*[:\-]\s*/, '')
        .strip
      next if stripped.empty?

      (map[tag] ||= []) << stripped
    end
  end
  map
end

# ---------------------------------------------------------------------------
# Standard changelog renderer — kept for callers that still want the
# raw commit list (e.g. some other lanes). Output is just the commit lines
# joined per-format, with no aggregation / no Tickets section.
# ---------------------------------------------------------------------------

def _smf_standard_changelog(changelog, changelog_format)
  return '' if changelog.nil? || changelog.empty?

  case changelog_format
  when :markdown
    changelog.join("\n")
  when :slack_markdown
    changelog.map { |commit| "• #{commit.gsub(/\A-\s*/, '')}\n" }.join
  when :html
    '<ul>' + changelog.map { |commit| "<li>#{commit.gsub(/\A-\s*/, '')}</li>" }.join + '</ul>'
  else
    changelog.join("\n")
  end
end

# ---------------------------------------------------------------------------
# Internal helpers (CBENEFIOS-2508)
# ---------------------------------------------------------------------------

def _smf_render_ticket_block(ticket, commit_messages, fmt)
  tag = ticket[:tag].to_s
  title = ticket[:title].to_s
  link = ticket[:link]

  headline = _smf_format_ticket_headline(tag, title, link, fmt)
  sub_bullets = _smf_format_sub_bullets(commit_messages || [], title, fmt)

  case fmt[:link_style]
  when :html
    "#{fmt[:primary_bullet][:prefix]}#{headline}#{sub_bullets}#{fmt[:primary_bullet][:postfix]}"
  else
    "#{fmt[:primary_bullet][:prefix]}#{headline}#{fmt[:primary_bullet][:postfix]}#{sub_bullets}"
  end
end

def _smf_format_ticket_headline(tag, title, link, fmt)
  rendered_tag = _smf_render_tag(tag, link, fmt)
  return rendered_tag if title.nil? || title.empty?

  "#{rendered_tag}: #{title}"
end

def _smf_render_tag(tag, link, fmt)
  case fmt[:link_style]
  when :html
    return tag if link.nil? || link.empty?

    "<a href=\"#{link}\">#{tag}</a>"
  when :slack
    return tag if link.nil? || link.empty?

    "<#{link}|#{tag}>"
  else
    tag
  end
end

def _smf_format_sub_bullets(commit_messages, ticket_title, fmt)
  cleaned = commit_messages.map { |m| m.to_s.strip }.reject(&:empty?).uniq
  cleaned = cleaned.reject { |m| _smf_messages_similar?(m, ticket_title) }
  return '' if cleaned.empty?

  case fmt[:link_style]
  when :html
    sub = cleaned.map { |m| "<li>#{m}</li>" }.join
    "<ul>#{sub}</ul>"
  else
    cleaned.map { |m| "#{fmt[:sub_bullet][:prefix]}#{m}#{fmt[:sub_bullet][:postfix]}" }.join
  end
end

def _smf_messages_similar?(message, ticket_title)
  return false if message.nil? || ticket_title.nil?
  return false if message.empty? || ticket_title.empty?

  normalised_message = _smf_normalise(message)
  normalised_title = _smf_normalise(ticket_title)

  return true if normalised_message == normalised_title
  return true if normalised_title.include?(normalised_message) && normalised_message.length >= 20
  return true if normalised_message.include?(normalised_title) && normalised_title.length >= 20

  false
end

def _smf_normalise(string)
  string.downcase.gsub(/\s+/, ' ').gsub(/[^a-z0-9\s]/i, '').strip
end

def _smf_orphan_commits(changelog_lines)
  # PURE regex — no PR-body fetching. A commit whose title doesn't directly
  # reference a Jira tag goes under "Sonstige Änderungen", even if the PR
  # body would have one. Acceptable: such commits are usually maintenance,
  # config changes, dependency bumps.
  changelog_lines.select do |line|
    next false if line.nil? || line.strip.empty?

    _smf_find_ticket_tags_in(line).empty?
  end
end

def _smf_render_orphan_line(line, fmt)
  body = line.to_s.sub(/\A-\s*/, '').strip
  return '' if body.empty?

  case fmt[:link_style]
  when :html
    "<li>#{body}</li>"
  else
    "#{fmt[:primary_bullet][:prefix]}#{body}#{fmt[:primary_bullet][:postfix]}"
  end
end

def _smf_render_section_header(title, fmt)
  "#{fmt[:section_header][:prefix]}#{title}#{fmt[:section_header][:postfix]}"
end
