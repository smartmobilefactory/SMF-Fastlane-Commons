FORMAT_ELEMENTS = {
  html: {
    spacer: '<hr>',
    bullet_point: {
      prefix: '<li>',
      postfix: '</li>'
    },
    section: {
      header: {
        prefix: '<h4>',
        postfix: '</h4>'
      },
      body: {
        prefix: '<ul>',
        postfix: '</ul>'
      }
    }

  },
  markdown: {
    spacer: "\n\n----",
    bullet_point: {
      prefix: '- ',
      postfix: "\n"
    },
    section: {
      header: {
        prefix: "\n",
        postfix: "\n\n"
      },
      body: {
        prefix: '',
        postfix: ''
      }
    }
  }
}.freeze

def _smf_standard_changelog(changelog, changelog_format)
  standard_changelog = ''

  if changelog_format == :markdown
    standard_changelog = changelog.join("\n")
  elsif changelog_format == :html
    standard_changelog =
      FORMAT_ELEMENTS[:html][:section][:body][:prefix] +
      changelog.map { |commit|
        FORMAT_ELEMENTS[:html][:bullet_point][:prefix] +
        commit.gsub('- ', '') +
        FORMAT_ELEMENTS[:html][:bullet_point][:postfix]
      }.join('')
    FORMAT_ELEMENTS[:html][:section][:body][:postfix]
  end

  standard_changelog
end

def _smf_section_header(title, changelog_format)
  FORMAT_ELEMENTS[changelog_format][:section][:header][:prefix] +
  title +
  FORMAT_ELEMENTS[changelog_format][:section][:header][:postfix]
end

def _smf_normal_tickets_section(tickets, changelog_format)

  section = _smf_section_header('Tickets:', changelog_format)
  section += FORMAT_ELEMENTS[changelog_format][:section][:body][:prefix]

  tickets[:normal].sort_by! { |ticket| ticket[:tag] }
  tickets[:normal].each do |ticket|
    related = _smf_linked_tickets_string(ticket[:linked_tickets], changelog_format)
    ticket_linked =
      FORMAT_ELEMENTS[changelog_format][:bullet_point][:prefix] +
      _smf_ticket_to_link(ticket, changelog_format) + related +
      FORMAT_ELEMENTS[changelog_format][:bullet_point][:postfix]
    section += ticket_linked
  end

  section += FORMAT_ELEMENTS[changelog_format][:section][:body][:postfix]

  section
end

def _smf_related_prs_section(tickets, changelog_format)

  section = _smf_section_header("Related Pull Requests:", changelog_format)
  section += FORMAT_ELEMENTS[changelog_format][:section][:body][:prefix]

  tickets[:pr].sort_by! { |pr_tag| pr_tag[:tag] }
  tickets[:pr].each do |pr|
    ticket_linked =
      FORMAT_ELEMENTS[changelog_format][:bullet_point][:prefix] +
      _smf_ticket_to_link(pr, changelog_format, false) +
      FORMAT_ELEMENTS[changelog_format][:bullet_point][:postfix]
    section += ticket_linked
  end

  section += FORMAT_ELEMENTS[changelog_format][:section][:body][:postfix]

  section
end

def _smf_linked_tickets_section(tickets, changelog_format)
  section = _smf_section_header('Linked Tickets:', changelog_format)
  section += FORMAT_ELEMENTS[changelog_format][:section][:body][:prefix]

  tickets[:linked].sort_by! { |ticket| ticket[:tag] }
  tickets[:linked].each do |ticket|
    section +=
      FORMAT_ELEMENTS[changelog_format][:bullet_point][:prefix] +
      _smf_ticket_to_link(ticket, changelog_format) +
      FORMAT_ELEMENTS[changelog_format][:bullet_point][:postfix]
  end

  section += FORMAT_ELEMENTS[changelog_format][:section][:body][:postfix]

  section
end

def _smf_unknown_tickets_section(tickets, changelog_format)
  section = _smf_section_header('Unknown Tickets:', changelog_format)
  section += FORMAT_ELEMENTS[changelog_format][:section][:body][:prefix]

  tickets[:unknown].sort_by! { |ticket| ticket[:tag] }
  tickets[:unknown].each do |ticket|
    section +=
      FORMAT_ELEMENTS[changelog_format][:bullet_point][:prefix] +
      ticket[:tag] +
      FORMAT_ELEMENTS[changelog_format][:bullet_point][:postfix]
  end

  section += FORMAT_ELEMENTS[changelog_format][:section][:body][:postfix]

  section
end

def _smf_generate_changelog(changelog, tickets, changelog_format)
  standard_changelog = changelog.nil? ? '' : _smf_standard_changelog(changelog, changelog_format)
  spacer = changelog.nil? ? '' : FORMAT_ELEMENTS[changelog_format][:spacer]

  normal_tickets = _smf_normal_tickets_section(tickets, changelog_format)
  linked_tickets = _smf_linked_tickets_section(tickets, changelog_format)
  related_prs = _smf_related_prs_section(tickets, changelog_format)
  unknown_tickets = _smf_unknown_tickets_section(tickets, changelog_format)

  spacer = '' if tickets[:normal].empty? and
                tickets[:linked].empty? and
                tickets[:unknown].empty? and
                tickets[:pr].empty?
  normal_tickets = '' if tickets[:normal].empty?
  linked_tickets = '' if tickets[:linked].empty?
  related_prs = '' if tickets[:pr].empty?
  unknown_tickets = '' if tickets[:unknown].empty?

  standard_changelog + spacer + normal_tickets + linked_tickets + related_prs + unknown_tickets
end

def _smf_linked_tickets_string(related_tickets, changelog_format)
  return '' if related_tickets.empty?

  related = ' (linked tickets: '
  related_tickets.each do |related_ticket|
    related += _smf_ticket_to_link(related_ticket, changelog_format,false) + ', '
  end

  related.chop.chop + ')'
end

def _smf_ticket_to_link(ticket, changelog_format, use_title = true)
  ticket_string = ticket[:tag]

  return ticket_string if ticket[:link].nil?

  ticket_string += ": #{ticket[:title]}" if use_title
  if changelog_format == :html
    ticket_link =  "<a href=\"#{ticket[:link]}\">#{ticket_string}</a>"
  elsif changelog_format == :markdown
    ticket_link = "[#{ticket_string}](#{ticket[:link]})"
  end

  ticket_link
end