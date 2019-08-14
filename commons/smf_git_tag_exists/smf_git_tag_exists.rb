private_lane :smf_git_tag_exists do |options|
  UI.message('check if git tag exists')
  tag = options[:tag]

  raise "The Git tag \"#{tag}\" already exists! The build job will be aborted to avoid builds with the same build number." if git_tag_exists(tag: tag)

end
