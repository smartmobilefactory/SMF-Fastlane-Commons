### Build Precheck

Precheck lane, to detect if a `build_variant` could be build.
Common issues could be detected here.

This lane will crash if something is not set properly.


Example Call:

```
smf_build_precheck(
    upload_itc: <Config.json flag, set if the app should be uploaded to itc>,
    itc_apple_id: <the itunce connect apple id>,
    pods_spec_repo:  <path to podspec> # only needed for ios_frameworks to check if there is a https url given as podspec path
)
```