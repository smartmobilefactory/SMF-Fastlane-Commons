# Get Started
This documentation helps you understand the Fastlane Commons which are used by Jenkins Pipeline Commons.

## Fastlane and Jenkins Pipeline Commons
To begin with, it is good to know how the Fastlane Commons and the Jenkins Pipeline Commons work together.

The Pipeline Commons contain seperated files for iOS Apps and Frameworks and Android Apps and Frameworks. Each file contains stages to run on pull requests and builds. 

From every stage one specific Fastlane lane is called. Those lanes are defined in the corresponding setup file like *ios_setup.rb*.

Every specific lane in the setup files has a "super" lane recognizable by the `super` keyword. Why is that? :confused:
As mentioned before the specific lanes will be called directly from the stages in the Jenkins Pipeline Commons. You can think of them as default lanes. In most cases they just call their super lane. If you would like to modify these default lanes you would often like to call the super lane with different parameters. 

To learn how to overwrite the default lanes to customize your build process have a look at the Custom Behaviour section.

# Platform Specific Setup
In the following sections the default lanes will be explained. 

## Android Setup
`smf_setup_dependencies`: This lane does nothing. :grin: You could overwrite it to use Phraseapp. To get to know how have a look at the example in the Custom Behaviour. :wink:

`smf_run_unit_tests`: This lane usually runs junit tests.

`smf_pipeline_increment_build_number`: This lane increments the build number. :chart_with_upwards_trend: To get the current build number, the last tag from GitHub will be fetched. If the build number in the project is greater than the number from GitHub it will be used.

`smf_pipeline_create_git_tag`: This lane creates a tag on GitHub which is build using the following pattern: *build/\<build variant\>/\<build number\>*.

`smf_build`: This lane builds the app and saves the apk. :floppy_disk: The Keystore will be pulled if the keystore folder is defined in the Config json. To add a folder name just add `keystore` to the build variant. :key:
```
"live": {
      "variant": "productionRelease",
      "keystore": "Example"
    }
```

`smf_generate_changelog`: This lane generates the changelog and saves it in a temporary file to be usually read for notifications e.g. on Slack. The changelog will be generates by looking for the last tag on Github, which contains the build variant which you build. The changes between the new build and the last one will be listed. :clipboard:

`smf_upload_to_appcenter`: This lane uploads the apk to App Center if a `appcenter_id` is defined for the build variant Config.json. :arrow_up: In addition it uploads the apk to hockey if a `hockeyapp_id` is given for the build variant.
```
 "live": {
       "variant": "productionRelease",
       "keystore": "Example",
       "appcenter_id": "ExampleID"
     }
```

`smf_push_git_tag_release`: This lane pushes changes to GitHub using the created tag.

`smf_send_slack_notification`: This lanes sends the default build success notification to Slack. :envelope::white_check_mark:

`smf_linter`: This lane runs lint tasks like klint.

`smf_pipeline_danger`: This lanes runs danger which will send the results from the lint tasks to GitHub. :rotating_light:

`smf_pipeline_update_android_commons`: This lane updates the Android Commons.

## iOS Setup
`smf_setup_dependencies`: This lane install pods if a podfile is present in the project. It also checks multiple properties (duplicated build numbers, is there an editable app version, etc.) to reduce the risk of errors when uploading to iTunes Connect. 

`smf_pipeline_increment_build_number`: *See Android.*

`smf_pipeline_create_git_tag`: *See Android.*

`smf_build`: This lane downloads the provisioning profiles and builds the app and saves the IPA. :floppy_disk:

`smf_generate_changelog`: *See Android.*

`smf_upload_dsyms`: This lane uploads the symbolication files to sentry. :arrow_up:

`smf_upload_to_appcenter`: This lane uploads the IPA to App Center if a `appcenter_id` is given for the build variant in the Config.json. :arrow_up: Further, this lane uploads the IPA to hockey if a `hockeyapp_id` is given for the build variant.
```
 "live": {
       "variant": "productionRelease",
       "appcenter_id": "ExampleID"
     }
```
`smf_upload_to_itunes`: This lane uploads to app to Testflight. :arrow_up::airplane:

`smf_push_git_tag_release`: This lane pushes changes to GitHub using the created tag. Is also creates a GitHub release.

`smf_send_slack_notification`: *See Android.*

`smf_generate_files`: This lane generates the Jenkinsfile if it was outdated.

`smf_unit_tests`: This lane run unit tests.

`smf_linter`: This lane runs lint tasks like swift lint.

`smf_pipeline_danger`: *See Android.*

# Custom Behaviour

To add custom behaviour for your app you can simply overwrite the default lane in the Fastfile in your project. :wrench:

## Example
Use Phraseapp.
```
override_lane :smf_setup_dependencies do |options[
    smf_super_setup_dependencies(options) #Call the "super" lane to have the usual functionality.
    
    smf_sync_with_phrase_app(@smf_fastlane_config[:build_variants][build_variant.to_sym][:phrase_app]) #Call the phraseapp lane to use Phraseapp.
end
```