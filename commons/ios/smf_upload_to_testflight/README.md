# smf_upload_to_testflight

This lane uploads the build to Testflight using Pilot's lane *upload_to_testflight*.

### Example
Upload the build to Testflight.
```
smf_upload_to_testflight(
    build_variant: "alpha",                     # The currently building build variant
    itc_team_id: '',                            # ID of your App Store Connect team
    username: '',                               # Optional, Apple ID Username which is by default 'development@smfhq.com'.
    apple_id: '',                               # Optional, Apple ID property in the App Information section in App Store Connect which is by default 'development@smfhq.com' 
    skip_waiting_for_build_processing: false    # Optional, by default it is false.,
    slack_channel: "ci_error_log",              # Channel name to log errors and warnings to
    app_identifier: "",                         # The apps idnetifier
    upload_itc: true                            # should the app be uploaded to itunes
)
``` 