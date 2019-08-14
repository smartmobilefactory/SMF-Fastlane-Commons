desc "Tag the current git commit."
private_lane :smf_add_git_tag do |options|

  tag = options[:tag]

  UI.important("Adding git tag: #{tag}")
  add_git_tag(tag: tag)
end