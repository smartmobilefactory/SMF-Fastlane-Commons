# smf_upload_to_sentry

This lane uploads symbolication files to Sentry by using the *sentry_upload_dsym* lane. 

### Example
Upload the files to Sentry.
```
smf_upload_to_sentry(
    org_slug: '',
    project_slug: ''
)
```