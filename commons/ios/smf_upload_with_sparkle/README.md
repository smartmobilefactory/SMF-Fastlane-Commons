# smf_upload_with_sparkle

This lane uploads the .dmg file with Sparkle.

### Example
Uploads the .dmg to Sparkle.
```
smf_upload_with_sparkle(
    build_variant: "alpha",                     # The currently building build variant
    scheme: <scheme>,
    app_name = <name of the .app file>                        
    sparkle_dmg_path: <path to file>,           # The Path to the .dmg file
    sparkle_upload_user: <>,
    sparkle_upload_url: <>,
    sparkle_version: <>,
    sparkle_signing_team: <>,
    sparkle_xml_name: <>
)
``` 