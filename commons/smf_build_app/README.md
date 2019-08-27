### Build App

#### iOS

Builds the iOS app by first ensuring the correct xcode version and then using gym to actually build the app.

NOTE: The smf_download_provisioning_profiles lane has to be called before calling this lane.

#### Android

Builds the android app. 🎉

Example:

smf_build_app(build_variant: <build variant>)

