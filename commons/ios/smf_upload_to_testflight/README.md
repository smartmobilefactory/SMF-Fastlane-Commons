# smf_upload_to_testflight

This lane uploads the build to Testflight using Pilot's lane *upload_to_testflight*.

## Authentication

This lane supports both modern App Store Connect API key authentication and legacy username/password authentication:

1. **App Store Connect API Key (Recommended)**: If the following environment variables are set, the lane will use API key authentication:
   - `APP_STORE_CONNECT_API_KEY_ID`
   - `APP_STORE_CONNECT_API_KEY_ISSUER_ID`
   - `APP_STORE_CONNECT_API_KEY_PATH`

2. **Username/Password (Fallback)**: If API key environment variables are not available, the lane falls back to username/password authentication using the provided `apple_id` or the default `development@smfhq.com`.

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