## Sparkle Package Creator
This tool can be used to create a sparkle package (appcast, release html, app's dmg) for an already signed app dmg.
Therefore it needs the path to the .dmg and the build variant.

Example

```
smf_create_sparkle_package(
    build_variant: <build_variant>,
    dmg_path: <path to dmg>
)
```

This lane is used by a custom jenkins job which receives the .dmg and build variant as input parameters. The created package is then uploaded as an asset attached to a new release in this repo: https://github.com/smartmobilefactory/SMF-Sparkle-Packages-Container. The release tag is composed of the project name, build-variant and build number.