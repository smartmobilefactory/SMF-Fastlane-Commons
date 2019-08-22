### Fastlane Match Provisioning Profile Handler
Fastlane match handles the provisioning profiles for each app. This lane is used to download and setup the correct profiles and certificates 
to be used for building the app with the smf_build_app lane.

There are basically two cases for the match call:

1. There is no match entry in the project Config.json. In this case if will be checked whether the job is an enterprise build. 
If this is the case, match will be used with "enterprise" as profile type.
2. If there is a match entry in the projects Config.json ith will be check for completeness and then the values will be used for the match call.

In all other cases the build will probably fail because the profiles and certificates are needed for building the app.