private_lane :smf_upload_to_sentry do |options|

  org_slug = options[:org_slug]
  project_slug = options[:project_slug]

  sentry_upload_dsym(
      auth_token: ENV[$SENTRY_AUTH_TOKEN],
      org_slug: org_slug,
      project_slug: project_slug,
      url: 'https://sentry.solutions.smfhq.com/'
  )
end