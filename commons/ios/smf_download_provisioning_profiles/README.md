### Fastlane Match Provisioning Profile Handler
Fastlane match handles the provisioning profiles for each app. This lane is used to download and setup the correct profiles and certificates 
to be used for building the app with the smf_build_apple_app lane.

## Authentication

This lane supports both modern App Store Connect API key authentication and legacy username/password authentication:

1. **App Store Connect API Key (Recommended)**: If the following environment variables are set, the lane will use API key authentication:
   - `APP_STORE_CONNECT_API_KEY_ID`
   - `APP_STORE_CONNECT_API_KEY_ISSUER_ID`
   - `APP_STORE_CONNECT_API_KEY_PATH`

2. **Username/Password (Fallback)**: If API key environment variables are not available, the lane falls back to username/password authentication using the provided `apple_id` or the default `development@smfhq.com`.

There are basically two cases for the match call:

1. There is no match entry in the project Config.json. In this case it will be checked whether the job is an enterprise build. 
If this is the case, match will be used with "enterprise" as profile type.
2. If there is a match entry in the projects Config.json it will be check for completeness and then the values will be used for the match call.

In all other cases the build will probably fail because the profiles and certificates are needed for building the app.

Example Call:

```
smf_download_provisioning_profiles(
  team_id: "JZ2H644EU7",                                                            # The Team ID to use for the Apple Member Center.
  apple_id: "development@smfhq.com",                                                # The apple id to use. In most cases this will be development@smfhq.com.
  use_wildcard_signing: true,                                                       # If enabled, the Wildcard provisioning profile will be downloaded instead of one which matches the bundle identifier.
  bundle_identifier: "com.smartmobilefactory.enterprise.strato.osx.hidrive.alpha",  # The bundle identifier of the target configured on the Apple Developer portal
  use_default_match_config: false,                                                  # If no properties aree given in the config.json this should be set to true so the default settings are used for enterprise alpha/beta builds.
  match_read_only: true,                                                            # If enabled match only reads existing profiles and signing certificates and does not create new ones or updates any existing ones.
  match_type: "appstore",                                                           # The type can be one of the following values: "appstore", "adhoc", "development", "enterprise"
  extensions_suffixes: ["PushNotificationServiceExtension"],                          # See special parameters below
  build_variant: "alpha",                                                           # the build variant of the current build
  # template_name: "Contact Note Field Access beta",                               # DEPRECATED: Removed due to Apple API changes (May 2025)
  force: false,                                                                     # Optional: Renew the provisioning profiles every time you run match
  platform: 'ios'                                                                   # Optional: the platform, either 'ios' or 'macos', defaults to :ios  
)
```
#### Special Parameter Infos:

| Parameter | Optional | Default | Info |
| :----: | :----: | :----: | :--- |
| force | `true`| `false` | Renew the provisioning profiles every time you run match. |
| extensions_suffixes | `true`| `[]` | If the project contains extensions, a list of extension suffixes (when appended to the apps bundle identifier produce the extensions bundle identifier) can be provided for which match will be executed, too.  |