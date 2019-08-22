### Build App

#### iOS

This lane is called to build the app. Before the call the smf_download_provisioning_profiles lane has to be called. After that xcode_select is called to choose the correct verison for the project. Then the fastlane action gym is used to build the app.