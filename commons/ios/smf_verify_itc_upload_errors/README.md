### Verify Common iTunes Connect Upload Errors

This lane checks multiple properties (duplicated build numbers, is there an editable app version, etc.) necessary for an iTC upload. By doing so it reducing the probability of errors when uploading to iTunes Connect.

Example:
```
smf_verify_itc_upload_errors(
        build_variant: "alpha",
        upload_itc: true,
        project_name: "BSR",
        itc_skip_version_check: false,
        username: "development@smfhq.com",
        itc_team_id: "JKSDf6SKDf",
        bundle_identifier: "com.smartmonilefactory.example"
    )
```