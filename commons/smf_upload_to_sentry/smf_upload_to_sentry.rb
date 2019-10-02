private_lane :smf_upload_to_sentry do |options|

  org_slug = options[:sentry_org_slug]
  project_slug = options[:sentry_project_slug]
  build_variant_org_slug = options[:sentry_org_slug]
  build_variant_project_slug = options[:sentry_project_slug]
  slack_channel = options[:slack_channel]

  has_sentry_project_settings = !org_slug.nil? && !project_slug.nil?
  has_sentry_variant_settings = !build_variant_org_slug.nil? && !build_variant_project_slug.nil?

  use_sentry = has_sentry_project_settings || has_sentry_variant_settings
  UI.message("Will upload to Sentry: #{use_sentry}")

  if use_sentry
    begin

      # If a build variant overrides the sentry settings, use the variant settings
      if !build_variant_org_slug.nil? && !build_variant_project_slug.nil?
        org_slug = org_slug_variant
        project_slug = project_slug_variant
      end

      sentry_upload_dsym(
          auth_token: ENV[$SENTRY_AUTH_TOKEN],
          org_slug: org_slug,
          project_slug: project_slug,
          url: 'https://sentry.solutions.smfhq.com/'
      )

    rescue => exception
      UI.important("Warning: Dsyms could not be uploaded to Sentry !")

      smf_send_message(
          title: "Failed to upload dsyms to Sentry for #{smf_get_default_name_of_app(options[:build_variant])} 😢",
          type: "warning",
          exception: exception,
          slack_channel: slack_channel
      )
    end
  end
end