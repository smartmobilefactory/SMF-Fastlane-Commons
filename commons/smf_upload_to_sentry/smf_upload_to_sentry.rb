private_lane :smf_upload_to_sentry do |options|

  build_variant = options[:build_variant]

  org_slug = get_sentry_org_slug
  project_slug = get_sentry_project_slug

  org_slug_variant = get_variant_sentry_org_slug(build_variant)
  project_slug_variant = get_variant_sentry_project_slug(build_variant)

  # If a build variant overrides the sentry settings, use the variant settings
  if !org_slug_variant.nil? && !project_slug_variant.nil?
    org_slug = org_slug_variant
    project_slug = project_slug_variant
  end

  sentry_upload_dsym(
      auth_token: $SENTRY_AUTH_TOKEN,
      org_slug: org_slug,
      project_slug: project_slug,
      url: $SENTRY_URL
  )
end