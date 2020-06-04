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
    spacer: "\n\n--------------------------------------------",
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
    standard_changelog = "<ul>#{changelog.map {|commit| "<li>#{commit.gsub('- ', '')}</li>"}.join('')}</ul>"
  end

  return standard_changelog
end

def _smf_section_header(title, changelog_format)
  FORMAT_ELEMENTS[changelog_format][:section][:header][:prefix] +
  title +
  FORMAT_ELEMENTS[changelog_format][:section][:header][:postfix]
end

def _smf_normal_tickets_section(tickets, changelog_format)

  section += _smf_section_header('Tickets:', changelog_format)
  section += FORMAT_ELEMENTS[changelog_format][:section][:body][:prefix]

  tickets[:internal].sort_by! { |ticket| ticket[:tag] }
  tickets[:internal].each do |ticket|
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

def _smf_linked_tickets_section(tickets, changelog_format)
  section += _smf_section_header('Linked Tickets:', changelog_format)
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
  section += _smf_section_header('Unknown Tickets:', changelog_format)
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
  standard_changelog = _smf_standard_changelog(changelog, changelog_format)
  spacer = FORMAT_ELEMENTS[changelog_format][:spacer]

  normal_tickets = _smf_normal_tickets_section(tickets, changelog_format)
  linked_tickets = _smf_linked_tickets_section(tickets, changelog_format)
  unknown_tickets = _smf_unknown_tickets_section(tickets, changelog_format)

  spacer = '' if tickets[:normal].empty? and tickets[:linked_tickets].empty? and tickets[:unknown].empty?
  normal_tickets = '' if tickets[:normal].empty?
  linked_tickets = '' if tickets[:linked_tickets].empty?
  unknown_tickets = '' if tickets[:unknown].empty?

  standard_changelog + spacer + normal_tickets + linked_tickets + unknown_tickets
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