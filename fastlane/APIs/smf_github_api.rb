# get PR body, title and commits for a certain pull request
def smf_github_fetch_pull_request_data(pr_number)
  repo_name = smf_remote_repo_name

  repo_owner = smf_remote_repo_owner
  repo_owner = 'smartmobilefactory' if repo_owner.nil?

  base_url = "https://api.github.com/repos/#{repo_owner}/#{repo_name}/pulls/#{pr_number}"

  pull_request = _smf_https_get_request(
    base_url,
    :token,
    ENV[$SMF_GITHUB_TOKEN_ENV_KEY]
  )

  title = _try_dig(pull_request, :title)
  body = _try_dig(pull_request, :body)
  pr_link = _try_dig(pull_request, :html_url)
  branch = _try_dig(pull_request, :head)

  unless branch.nil?
    branch = _try_dig(branch, :ref)
  end

  commits = _smf_https_get_request(
    base_url + '/commits',
    :token,
    ENV[$SMF_GITHUB_TOKEN_ENV_KEY]
  )

  begin
    commits = commits.map {|commit| commit.dig(:commit, :message)}.compact.uniq
  rescue
    commits = nil
  end

  pr_data = {
    body: body,
    title: title,
    commits: commits,
    pr_link: pr_link,
    branch: branch
  }

  pr_data
end
