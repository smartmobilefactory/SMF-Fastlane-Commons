TICKET_BLACKLIST = [
  /UTF-*/,
  /UNICODE*/,
]


def smf_generate_tickets(changelog)

  tickets = {
    normal: [],
    linked: [],
    pr: [],
    unknown: []
  }

  return tickets if changelog.nil?

  ticket_tags = []

  # find all ticket tags
  changelog.each do |commit_message|
    # find ticket tags in the commit message itself
    ticket_tags += _smf_find_ticket_tags_in(commit_message)
    # if the commit message was a merge, check the corresponding PR
    ticket_tags += _smf_find_ticket_tags_in_related_pr(commit_message)
  end

  ticket_tags.uniq.each do |ticket_tag|
    # If the found tag is not really a ticket but a reference to a PR like 'PR-123' create a PR reference tag
    related_pr_tag = _smf_make_pr_reference(ticket_tag)

    unless related_pr_tag.nil?
      tickets[:pr].push(related_pr_tag) unless related_pr_tag[:link].nil?
      next
    end

    fetched_data = _smf_fetch_ticket_data_for(ticket_tag)
    title = fetched_data[:title]
    base_url = fetched_data[:base_url]
    linked_issues = fetched_data[:linked_tickets]

    if base_url.nil?
      unknown_ticket = { tag: ticket_tag }
      tickets[:unknown].push(unknown_ticket)
      next
    end

    link = File.join(base_url, 'browse', ticket_tag)

    linked_tickets = linked_issues
    # get remote links and check them for tickets
    linked_tickets += _smf_fetch_remote_tickets_for(ticket_tag, base_url)

    new_ticket = {
      tag: ticket_tag,
      link: link,
      title: title,
      linked_tickets: linked_tickets.uniq
    }

    tickets[:normal].push(new_ticket)
    tickets[:linked].concat(linked_tickets)
  end

  tickets[:normal].uniq!
  tickets[:linked].uniq!
  tickets[:pr].uniq!
  tickets[:unknown].uniq!

  tickets
end

def _smf_make_pr_reference(ticket_tag)
  UI.message("Making pr tag for: #{ticket_tag}")
  pr_number_matches = ticket_tag.scan(/^PR-([0-9]+)$/)
  return nil if pr_number_matches.empty?

  pr_url = _smf_fetch_pull_request_data(pr_number_matches.first.first)
  new_ticket = {
    tag: ticket_tag,
    link: pr_url
  }

  UI.message("Created pr tag: #{new_ticket}")

  new_ticket
end

def smf_jira_ticket_regex_string
  min_ticket_name_length = 2
  max_ticket_name_length = 14

  min_ticket_number_length = 1
  max_ticket_number_length = 8

  # This regex matches anything that starts with 2 or 14 captial letters, followed by a dash followed by 1 to 8 digits
  "[A-Z]{#{min_ticket_name_length},#{max_ticket_name_length}}-[0-9]{#{min_ticket_number_length},#{max_ticket_number_length}}"
end

def _smf_find_ticket_tags_in(string)

  if string.nil?
    return []
  end

  regex = Regexp.new(smf_jira_ticket_regex_string)
  tickets = string.scan(regex)

  _smf_filter_blacklisted_tickets(tickets.uniq)
end

def smf_find_jira_ticket_tags_in_pr(pr_data)

  tickets = []

  pr_data.each do |section, content|
    if section == :commits
      if !content.nil? then
        content.each do |message|
          tickets.concat(_smf_find_ticket_tags_in(message)).uniq
        end
      end
    else
      tickets.concat(_smf_find_ticket_tags_in(content)).uniq
    end
  end

  tickets.uniq
end

def _smf_filter_blacklisted_tickets(tickets)
  filtered_tickets = tickets.select { |ticket|
    not_on_blacklist = true
    TICKET_BLACKLIST.each { |blacklist_entry|
      not_on_blacklist = not_on_blacklist && ticket.scan(blacklist_entry).empty?
    }

    not_on_blacklist
  }

  filtered_tickets
end