# smf_upload_to_appcenter

This lane uploads the build to AppCenter by using the *appcenter_upload* lane. 

### Example
Upload the apk on Android or the ipa to AppCenter.
```
smf_upload_to_appcenter(
        apk_file: <name of apk>, #Name of the apk_file
        apk_path: <path of apk>, #Optional, by default the path will be get from all grade apk ouput paths from the lane context
        build_number: get_build_number_of_app, #Needed only for mac apps
        app_secret: get_app_secret(build_variant), #The secret of the app from AppCenter
        escaped_filename: get_escaped_filename(build_variant), #Needed only for iOS
        path_to_ipa_or_app: get_path_to_ipa_or_app(build_variant), #Needed only for iOS
        is_mac_app: is_mac_app(build_variant), #Optional, false by default
        podspec_path: get_podspec_path(build_variant) #Needed for mac apps
)
```

## get_app_details
This method takes the *app_secret* and requests all apps from the AppCenter API. Further, the app which has the relevant *app_secret* will be searched and the app name and the owner name will be returned. If there is no app which has a matching app secret an exception will be raised.  

### Example
Get the app name and the owner name of the app which has the app secret *test-app-secret*.
```
get_app_details(<test-app-secret>)
```
