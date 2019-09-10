### Build iOS App

Builds the iOS app by first ensuring the correct xcode version and then using gym to actually build the app.

NOTE: The smf_download_provisioning_profiles lane has to be called before calling this lane.


Example Call:

```
smf_build_ios_app(
    skip_package_ipa: false,                                # Set to true to skip package ipa
    bulk_deploy_params: {index: 0, count: 4},               # Hashmap which holds how many build variants are build and which one the current one is (index)
    scheme: "DGB Alpha",                                    # The scheme name as you see it in XCode
    should_clean_project: true,                             # If disabled, xcodebuild won't be told to clean before building an app.
    required_xcode_version: "10.2",                         # The projects xcode version      
    project_name: "DGB",                                    # The projects name
    xcconfig_name: "config.xcconfig",                       # This is needed if xcconfig files are used instead of targets.
    code_signing_identity: "iPhone Distribution: Hidrive",  # The name of the signing certificate attached to the provisioning profile. This can be found in XCode under Build Settings/Code Signing Identity
    upload_itc: false,                                      # If enabled, the .ipa will be uploaded to App Store Connect.
    upload_bitcode: true,                                   # If disabled, Bitcode won't be uploaded.
    export_method: false,                                   # The Xcode archive export method to use. This needs to be set for special cases only.
    icloud_environment                                      # ("Development" or "Production"): If the app uses iCloud capabilities, this has to be set accordingly for each target.             
)

```

### Build Android App

Builds the android app. 🎉

Example Call:

```
smf_build_android_app(
    build_variant: "Alpha",                     # The name of the build variant
    keystore_folder: "keystore_folder_name"     # Name of the keystore folder for this project (in the Keystore Repository)      
)

```

