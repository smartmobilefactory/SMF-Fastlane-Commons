TICKET_BLACKLIST = [
  /UTF-*/,
  /UNICODE*/,
]

def smf_generate_tickets_from_tags(ticket_tags, options = {})
  target_platform = options[:target_platform]

  tickets = {
    normal: [],
    linked: [],
    pr: [],
    unknown: [],
    devops: []  # New category for DevOps tickets (CBENEFIOS-2079)
  }

  return tickets if ticket_tags.nil?

  ticket_tags.uniq.each do |ticket_tag|
    # If the found tag is not really a ticket but a reference to a PR like 'PR-123' create a PR reference tag
    related_pr_tag = _smf_make_pr_reference(ticket_tag)

    unless related_pr_tag.nil?
      tickets[:pr].push(related_pr_tag) unless related_pr_tag[:link].nil?
      next
    end

    fetched_data = smf_jira_fetch_ticket_data_for(ticket_tag)
    title = fetched_data[:title]
    base_url = fetched_data[:base_url]
    linked_issues = fetched_data[:linked_tickets]
    components = fetched_data[:components] || []

    if base_url.nil?
      unknown_ticket = { tag: ticket_tag }
      tickets[:unknown].push(unknown_ticket)
      next
    end

    link = File.join(base_url, 'browse', ticket_tag)

    linked_tickets = linked_issues
    # get remote links and check them for tickets
    linked_tickets += smf_jira_fetch_related_tickets_for(ticket_tag, base_url)

    # Detect platform from Jira components (CBENEFIOS-2079)
    ticket_platform = nil
    if defined?(smf_detect_platform_from_components)
      ticket_platform = smf_detect_platform_from_components(components)
    end

    new_ticket = {
      tag: ticket_tag,
      link: link,
      title: title,
      linked_tickets: linked_tickets.uniq,
      components: components,
      platform: ticket_platform
    }

    # Categorize ticket based on platform (CBENEFIOS-2079)
    if ticket_platform == :devops
      tickets[:devops].push(new_ticket)
    elsif target_platform.nil? || _smf_ticket_relevant_for_platform?(ticket_platform, target_platform)
      tickets[:normal].push(new_ticket)
      tickets[:linked].concat(linked_tickets)
    end
    # Tickets not relevant for target platform are silently excluded
  end

  tickets[:normal].uniq!
  tickets[:linked].uniq!
  tickets[:pr].uniq!
  tickets[:unknown].uniq!
  tickets[:devops].uniq!

  tickets
end

# Check if a ticket is relevant for the target platform
# @param ticket_platform [Symbol] Platform detected from Jira components
# @param target_platform [Symbol] Target build platform (:ios or :android)
# @return [Boolean] True if relevant
def _smf_ticket_relevant_for_platform?(ticket_platform, target_platform)
  return true if ticket_platform.nil?
  return true if ticket_platform == :both
  return true if ticket_platform == target_platform
  return false if ticket_platform == :devops
  return false if ticket_platform == :excluded

  # Default: include if uncertain
  true
end

def smf_get_ticket_tags_from_changelog(changelog)

  return nil if changelog.nil?

  ticket_tags = []

  # find all ticket tags
  changelog.each do |commit_message|
    # find ticket tags in the commit message itself
    ticket_tags += _smf_find_ticket_tags_in(commit_message)
    # if the commit message was a merge, check the corresponding PR
    ticket_tags += _smf_find_ticket_tags_in_related_pr(commit_message)
  end

  ticket_tags.uniq
end

# Get ticket tags with their associated commit messages
# @param changelog [Array<String>] Array of commit messages
# @return [Hash] { tags: [String], commits_by_tag: { tag => [messages] } }
def smf_get_ticket_tags_with_commits_from_changelog(changelog)
  return { tags: [], commits_by_tag: {} } if changelog.nil?

  ticket_tags = []
  commits_by_tag = {}

  changelog.each do |commit_message|
    # Find ticket tags in this commit
    tags_in_commit = _smf_find_ticket_tags_in(commit_message)
    tags_in_commit += _smf_find_ticket_tags_in_related_pr(commit_message)

    tags_in_commit.uniq.each do |tag|
      ticket_tags << tag

      # Store the commit message for this tag
      commits_by_tag[tag] ||= []

      # Clean up the commit message (remove tag, leading dash, etc.)
      clean_message = commit_message
        .sub(/^-\s*/, '')              # Remove leading dash
        .sub(/#{tag}[:\s]*/i, '')      # Remove ticket tag
        .sub(/^\s*[:\-]\s*/, '')       # Remove leading colon or dash
        .strip

      commits_by_tag[tag] << clean_message unless clean_message.empty?
    end
  end

  {
    tags: ticket_tags.uniq,
    commits_by_tag: commits_by_tag
  }
end

def _smf_make_pr_reference(ticket_tag)

  pr_number_matches = ticket_tag.scan(/^PR-([0-9]+)$/)
  return nil if pr_number_matches.empty?

  pr_link = smf_github_fetch_pull_request_data(pr_number_matches.first.first).dig(:pr_link)
  new_ticket = {
    tag: ticket_tag,
    link: pr_link
  }

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

def _smf_find_ticket_tags_in_related_pr(commit_message)

  matches = commit_message.scan(/.*\(#([0-9]*)\)\z/)
  return [] if matches.empty?

  pull_number = matches[0][0]

  UI.message("Analysing merge commit for PR-#{pull_number} ...")
  pr_data = smf_github_fetch_pull_request_data(pull_number)
  ticket_tags = smf_find_jira_ticket_tags_in_pr(pr_data)
  UI.message("Jira ticket(s) found for merge commit (##{pull_number}): #{ticket_tags}")

  ticket_tags
end
