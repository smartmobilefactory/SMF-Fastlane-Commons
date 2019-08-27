# smf_upload_to_sentry

This lane uploads symbolication files to Sentry by using the *sentry_upload_dsym* lane. 

### Example
Upload the files to Sentry.
```
smf_upload_to_sentry(
    build_variant: 'Alpha',
)
```
The *build_variant* is needed to call some methods like getting the sentry org slug.