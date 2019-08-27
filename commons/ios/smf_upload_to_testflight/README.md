# smf_upload_to_testflight

This lane uploads the build to Testflight using Pilot's lane *upload_to_testflight*.

### Example
Upload the build to Testflight.
```
smf_upload_to_testflight(
    username: '', #Optional, Apple ID Username which is by default automatically determined using the Appfile.
    skip_waiting_for_build_processing: false #Optional, by default it is false.
)
``` 