# smf_upload_to_appcenter

This lane uploads the build to AppCenter by using the *appcenter_upload* lane. 

### Example for iOS
Upload the ipa to AppCenter.
```
smf_ios_upload_to_appcenter(
        build_variant: "alpha"                  # Needed only for mac apps
        build_number: 83,                       # Needed only for mac apps
        app_id: "eg21g21-21g1g-12g13b3-2121",   # The id of the app from AppCenter
        escaped_filename: <escaped filename>,   # Needed only for iOS
        path_to_ipa_or_app: <path to ipa>,      # Needed only for iOS
        is_mac_app: false,                      # Optional, false by default
)
```

### Example for Android
Upload the apk to AppCenter.
```
smf_android_upload_to_appcenter(
        apk_path: <path to app apk>,            # Path to apk file
        aab_path: <path to app bundle>,         # Optional to apk_path
        app_id: "eg21g21-21g1g-12g13b3-2121",   # The id of the app from AppCenter
)
```

## get_app_details
This method takes the *app_id* and requests all apps from the AppCenter API. Further, the app which has the relevant *app_id* will be searched and the app name and the owner name will be returned. If there is no app which has a matching app id an exception will be raised.  

### Example
Get the app name and the owner name of the app which has the app id *"eg21g21-21g1g-12g13b3-2121"*.
```
get_app_details("eg21g21-21g1g-12g13b3-2121")
```
