### Build Precheck

Precheck lane, to detect if a `build_variant` could be build.
Common issues could be detected here.

This lane will crash if something is not set properly.


Example Call:

```
smf_build_precheck(
    upload_itc: <Config.json flag, set if the app should be uploaded to itc>,
    itc_apple_id: <the itunce connect apple id>
)
```