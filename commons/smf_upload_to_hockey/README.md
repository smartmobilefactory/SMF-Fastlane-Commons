# smf_upload_to_hockey

This lane uploads the build to Hockey by using the *hockey* lane. 

### Example for iOS
Upload the ipa to Hockey.
```
smf_ios_upload_to_hockey(
        build_number: 83,                       #Needed only for mac apps
        app_id: "eg21g21-21g1g-12g13b3-2121",   #The secret of the app from AppCenter
        escaped_filename: <escaped filename>,   #Needed only for iOS
        path_to_ipa_or_app: <path to ipa>,      #Needed only for iOS
        is_mac_app: false,                      #Optional, false by default
        podspec_path: <podspec path>            #Needed for mac apps
)
```

### Example for Android
Upload the apk to Hockey.
```
smf_android_upload_to_hockey(
        apk_path: <path to exampleApp>,         #Path to apk file
        app_id: "eg21g2121g1g12g13b32121",      #The id of the app from Hockey
)
```