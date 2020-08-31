# smf_upload_to_appcenter

This lane uploads the build to AppCenter by using the *appcenter_upload* lane. 

### Example for iOS
Upload the ipa to AppCenter.
```
smf_ios_upload_to_appcenter(
        destinations: "*",                      # Optional, set to 'Collaborators' by default
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
        appcenter_destinations: "*",            # To Distribute to all Distribution Groups
        apk_path: <path to app apk>,            # Path to apk file
        aab_path: <path to app bundle>,         # Optional to apk_path
        app_id: "eg21g21-21g1g-12g13b3-2121",   # The id of the app from AppCenter
)
```

## smf_upload_to_appcenter_precheck
- Check is webhooks are enabled for the app. Create it is needed.
- Check if the app is in all required destination groups. Tries to add the app the the required groups if needed.
```
smf_upload_to_appcenter_precheck(
        app_name: 'Android-CI-Playground',
        owner_name: 'SMF-Development-Organization',
        destinations: 'Collaborators,MY_GROUP'
)
```

## smf_appcenter_notify_destination_groups
Notify firebase appcenter webhook about the new release.
AppCenter itself webhooks only called for the first destination group.

```
smf_appcenter_notify_destination_groups(app_id, app_name, owner_name, destinations)
```

## smf_appcenter_get_app_details
This method takes the *app_id* and requests all apps from the AppCenter API. Further, the app which has the relevant *app_id* will be searched and the app name and the owner name will be returned. If there is no app which has a matching app id an exception will be raised.  

### Example
Get the app name and the owner name of the app which has the app id *"eg21g21-21g1g-12g13b3-2121"*.
```
app_name, owner_name, owner_id = smf_appcenter_get_app_details("eg21g21-21g1g-12g13b3-2121")
```
