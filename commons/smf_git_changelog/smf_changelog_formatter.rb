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
  },
  slack_markdown: {
    spacer: "\n\n_____________________________________________________________",
    bullet_point: {
      prefix: '• ',
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

  case changelog_format
  when :markdown
    standard_changelog = changelog.join("\n")
  when :slack_markdown
    standard_changelog =
        changelog.map { |commit|
          FORMAT_ELEMENTS[:slack_markdown][:bullet_point][:prefix] +
          commit.gsub('- ', '') +
          FORMAT_ELEMENTS[:slack_markdown][:bullet_point][:postfix]
        }.join('')
  when :html
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

def _smf_generate_changelog(changelog, changelog_format)
  standard_changelog = changelog.nil? ? '' : _smf_standard_changelog(changelog, changelog_format)

  standard_changelog
end