### Notarize MacOS App
This lane is used to notarize the a macOS app. 

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