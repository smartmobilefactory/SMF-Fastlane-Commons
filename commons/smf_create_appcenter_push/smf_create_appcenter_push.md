### Create AppCenter Push Notification

This Lane will trigger a Push Notification to Firebase Cloud Messaging Service.
Via Topics the SMF Hub (former: Appcenter/Hockey-Apps) will be informed that there is a new Build available.

#### Topic

The Topic is build by combining the owners id (from AppCenter) and the app id (from AppCenter) with a dash: `#{app_owner_id}-#{app_id}`


Example Call:

```
smf_create_appcenter_push(
    app_id: <AppCenter_App_Id>,
    app_owner: <AppCenter_App_Owner_id>,
    app_display_name:  <Display Name> # Display Name that will be used in the Push
)
```