private_lane :smf_upload_to_sentry do |options|

  build_variant = options[:build_variant]

  org_slug = options[:org_slug]
  project_slug = options[:project_slug]
  build_variant_org_slug = options[:build_variant_org_slug]
  build_variant_project_slug = options[:build_variant_project_slug]
  slack_channel = options[:slack_channel]
  escaped_filename = options[:escaped_filename]

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

      dsym_path = Pathname.getwd.dirname.to_s + "/build/#{escaped_filename}.app.dSYM.zip"
      UI.message("Constructed the dsym path \"#{dsym_path}\"")
      unless File.exist?(dsym_path)
        dsym_path = nil
        UI.message('Using nil as dsym_path as no file exists at the constructed path.')
      end

    rescue => exception
      _smf_sentry_raise_warning(exception, build_variant, slack_channel)
    end

    MAX_RETRIES = 10
    fail_count = 0
    success = false
    latest_exception = nil

    # 18.03.2021: Temporary fix added:
    # This retry loop is a temporary fix for an sentry cli issue
    # (see https://github.com/getsentry/sentry-fastlane-plugin/issues/38)
    # which causes the upload to subsequently fail.
    # This error seems to be some internal error in sentry.
    # We should keep an eye on it and if it gets fixed
    # this retry loop should be removed.

    while fail_count < MAX_RETRIES && !success
      begin
        # 06.12.2021: https://sosimple.atlassian.net/browse/SMFIT-1971
        # We are not using Fastlane because it requires a higher version of the CLI than what we have.
        # We can try again with Fastlane once our Sentry instance is updated (https://sosimple.atlassian.net/browse/SMFIT-1967)
        `sentry-cli --url https://sentry.solutions.smfhq.com/ --auth-token #{ENV[$SENTRY_AUTH_TOKEN]} upload-dsym --org #{org_slug} --project #{project_slug} #{dsym_path}`
        success = true
      rescue => exception
        UI.message("Upload attempt ##{fail_count} failed, retrying... ")
        fail_count += 1
        latest_exception = exception
      end
    end

    _smf_sentry_raise_warning(latest_exception, build_variant, slack_channel) unless success

  end
end

def _smf_sentry_raise_warning(exception, build_variant, slack_channel)
  UI.important('Warning: Dsyms could not be uploaded to Sentry !')

  smf_send_message(
    title: "Failed to upload dsyms to Sentry for #{smf_get_default_name_and_version(build_variant)} 😢",
    type: 'warning',
    exception: exception,
    slack_channel: slack_channel
  )
end