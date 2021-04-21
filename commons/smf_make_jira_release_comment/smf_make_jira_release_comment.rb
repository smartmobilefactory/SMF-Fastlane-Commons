desc 'Comments the build number and variant on all jira tickets released in a new build'

private_lane :smf_make_jira_realease_comment do |options|

  build_variant = options[:build_variant]

  comment = "Released in #{smf_get_default_name_of_app(build_variant)}"

  ticket_tags = smf_read_changelog(type: :ticket_tags)

  ticket_tags.each do |tag|
    UI.message("Commenting: #{comment} on ticket with tag: #{tag}")
    smf_jira_add_comment_to_ticket(tag, comment)
  end

end