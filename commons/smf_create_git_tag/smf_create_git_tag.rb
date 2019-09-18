private_lane :smf_create_git_tag do |options|

  build_variant = options[:build_variant]
  build_number = options[:build_number]

  tag = smf_get_tag_of_app(build_variant, build_number)
  add_git_tag(tag: tag)

  tag
end