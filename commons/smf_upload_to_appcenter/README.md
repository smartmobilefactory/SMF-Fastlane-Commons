# smf_upload_to_appcenter

This lane uploads the build to AppCenter by using the *appcenter_upload* lane. 

### Example
Upload the apk on Android or the ipa to AppCenter.
```
smf_upload_to_appcenter(
    build_variant: 'Alpha',
)
```
The *build_variant* is needed to call some methods like getting the app's secret.

## get_app_details
This method takes the *app_secret* and requests all apps from the AppCenter API. Further, the app which has the relevant *app_secret* will be searched and the app name and the owner name will be returned. If there is no app which has a matching app secret an exception will be raised.  

### Example
Get the app name and the owner name of the app which has the app secret *test-app-secret*.
```
get_app_details('test-app-secret')
```
