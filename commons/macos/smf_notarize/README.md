### Notarize MacOS App
This lane is used to notarize the a macOS app.

## Authentication

This lane supports both modern App Store Connect API key authentication and legacy username/password authentication:

1. **App Store Connect API Key (Recommended)**: If the following environment variables are set, the lane will use API key authentication:
   - `APP_STORE_CONNECT_API_KEY_ID`
   - `APP_STORE_CONNECT_API_KEY_ISSUER_ID`
   - `APP_STORE_CONNECT_API_KEY_PATH`

2. **Username/Password (Fallback)**: If API key environment variables are not available, the lane falls back to username/password authentication using the provided `username`. 

#####Special Parameter: Provider
The default value which is passed to the notarization tool for `asc_provider` is the current team id.
If another value should be used, the `notarization_custom_provider` field in the Config.json for the preferred build variant can be set. If this field is not null it will be used as `asc_provider`.

To find the correct `asc_provider` you can run: 

`xcrun altool --username "username" --password "password" --list-providers`

###Example

```
smf_notarize(
    should_notarize: <whether or not the app should be notarized>,
    dmg_path: <path to dmg>,
    bundle_id: <bundle identifier>,
    username: <apple id>,
    asc_provider: <team id>,	                                    # this is used as default if custom_provider is null		
    custom_provider: <custom provider name read form Config.json>   # optional
)
  
```