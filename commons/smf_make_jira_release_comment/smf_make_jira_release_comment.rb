desc 'Comments the build number and variant on all jira tickets released in a new build'

private_lane :smf_make_jira_realease_comment do |options|

  build_variant = options[:build_variant]
  name_and_version = smf_get_default_name_and_version(build_variant)

  next unless name_and_version

  comment = "Released in #{name_and_version}"

  ticket_tags = smf_read_changelog(type: :ticket_tags)

  # The comment always goes to the first configured Atlassian instance, which is
  # where smf_jira_add_comment_to_ticket posts. Tags that do not live there
  # produce nothing but a 404 in the build log, so they are skipped rather than
  # posted (RWCIT-2127). The lookup below is served from the per-build cache the
  # changelog already filled, so this costs no extra request.
  comment_base_url = smf_atlassian_base_urls.first

  Array(ticket_tags).each do |tag|
    if tag.to_s.match?(PR_REFERENCE_TAG_REGEX)
      UI.message("Skipping #{tag}: a pull request reference, not a Jira ticket")
      next
    end

    ticket_base_url = smf_jira_fetch_ticket_data_for(tag)[:base_url]

    if ticket_base_url.nil?
      UI.message("Skipping #{tag}: no Jira ticket behind it on any configured instance")
      next
    end

    unless ticket_base_url == comment_base_url
      UI.message("Skipping #{tag}: lives on #{ticket_base_url}, comments go to #{comment_base_url}")
      next
    end

    UI.message("Commenting: #{comment} on ticket with tag: #{tag}")
    smf_jira_add_comment_to_ticket(tag, comment)
  end

end