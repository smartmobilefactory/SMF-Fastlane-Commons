# smf_upload_to_sentry

This lane uploads symbolication files to Sentry by using the *sentry_upload_dsym* lane. 

### Example
Upload the files to Sentry.
```
smf_upload_to_sentry(
    build_variant: 'alpha',
    org_slug: <sentry organisation slug>,
    project_slug: <sentry project slug>,
    build_variant_org_slug: <build variant organisation slug>,
    build_variant_project_slug: <build variant project slug>,
    escaped_filename: <escaped scheme name>,
    slack_channel: 'test_channel'
    
)
```