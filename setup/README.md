# Get Started
This documentation helps you understand the Fastlane Commons which are used by Jenkins Pipeline Commons.

### Fastlane and Jenkins Pipeline Commons
To begin with, it is good to know how the Fastlane Commons and the Jenkins Pipeline Commons work together.

The Pipeline Commons contain seperated files for macOS App, iOS Apps and Frameworks and Android Apps and Frameworks. Each file contains stages to run on pull requests and builds. 

From every stage one specific Fastlane lane is called. Those lanes are defined in the corresponding setup file like *ios_setup.rb*.

Every specific lane in the setup files has a "super" lane recognizable by the `super` keyword. Why is that? :confused:
As mentioned before the specific lanes will be called directly from the stages in the Jenkins Pipeline Commons. You can think of them as default lanes. In most cases they just call their super lane. If you would like to modify these default lanes you would often like to call the super lane with different parameters. 

To learn how to overwrite the default lanes to customize your build process have a look at the *Custom Behaviour* section.

Table of Contents
=================

   * [Get Started](#get-started)
        * [Fastlane and Jenkins Pipeline Commons](#fastlane-and-jenkins-pipeline-commons)
   * [Table of Contents](#table-of-contents)
   * [Platform Specific Setup](#platform-specific-setup)
      * [iOS Setup](#ios-setup)
         * [Pull Request Lanes](#pull-request-lanes)
            * [smf_generate_files](#smf_generate_files)
            * [smf_setup_dependencies_pr_check/smf_setup_dependencies_build](#smf_setup_dependencies_pr_checksmf_setup_dependencies_build)
            * [smf_build](#smf_build)
            * [smf_unit_tests](#smf_unit_tests)
            * [smf_linter](#smf_linter)
            * [smf_pipeline_danger](#smf_pipeline_danger)
         * [Additional Lanes used for building](#additional-lanes-used-for-building)
            * [smf_generate_changelog](#smf_generate_changelog)
            * [smf_pipeline_increment_build_number](#smf_pipeline_increment_build_number)
            * [smf_pipeline_create_git_tag](#smf_pipeline_create_git_tag)
            * [smf_upload_dsyms](#smf_upload_dsyms)
            * [smf_upload_to_appcenter](#smf_upload_to_appcenter)
            * [smf_upload_to_itunes](#smf_upload_to_itunes)
            * [smf_push_git_tag_release](#smf_push_git_tag_release)
            * [smf_send_slack_notification](#smf_send_slack_notification)
      * [Android App Setup](#android-app-setup)
         * [Pull Request Lanes](#pull-request-lanes-1)
            * [smf_setup_dependencies_pr_check/smf_setup_dependencies_build](#smf_setup_dependencies_pr_checksmf_setup_dependencies_build-1)
            * [smf_pipeline_update_android_commons](#smf_pipeline_update_android_commons)
            * [smf_build](#smf_build-1)
            * [smf_run_unit_tests](#smf_run_unit_tests)
            * [smf_linter](#smf_linter-1)
            * [smf_pipeline_danger](#smf_pipeline_danger-1)
         * [Additional Lanes used for building](#additional-lanes-used-for-building-1)
            * [smf_generate_changelog](#smf_generate_changelog-1)
            * [smf_pipeline_increment_build_number](#smf_pipeline_increment_build_number-1)
            * [smf_pipeline_create_git_tag](#smf_pipeline_create_git_tag-1)
            * [smf_upload_to_appcenter](#smf_upload_to_appcenter-1)
            * [smf_generate_changelog](#smf_generate_changelog-2)
            * [smf_push_git_tag_release](#smf_push_git_tag_release-1)
   * [Common Setup](#common-setup)
        * [Fastlane Lanes](#fastlane-lanes)
            * [smf_pipeline_increment_build_number](#smf_pipeline_increment_build_number-2)
            * [smf_pipeline_create_git_tag](#smf_pipeline_create_git_tag-2)
            * [smf_generate_changelog](#smf_generate_changelog-3)
            * [smf_send_slack_notification](#smf_send_slack_notification-1)
            * [smf_pipeline_danger](#smf_pipeline_danger-2)
   * [Custom Behaviour](#custom-behaviour)
      * [Example](#example)

      
# Platform Specific Setup
In the following sections the default lanes for each platform will be explained. These are the lanes called for checking pull requests and builds.

For each platform they are ordered by the following criteria:
1. PR lanes before build lanes
2. Lanes that are only called during builds are chronologically arranged

## iOS App Setup

### Pull Request Lanes

#### `smf_generate_files`
This lane generates the Jenkinsfile if it was outdated. If there are other files which should be generate files you can overwrite this lane.

#### `smf_setup_dependencies_pr_check`/`smf_setup_dependencies_build`
These lanes install pods if a podfile is present in the project. They also check multiple properties (duplicated build numbers, is there an editable app version, etc.) to reduce the risk of errors when uploading to iTunes Connect. For this check `upload_itc` must be set to true in the Config.json. There is one lane for PR-Checks and one for Builds to be able to only run code for one of the two. For example Phrase-App should only be called during a build. To get to know how have a look at the [example](#Example`). :wink:

#### `smf_build`
This lane downloads the provisioning profiles and builds the app and saves the IPA. :floppy_disk:

#### `smf_unit_tests`
This lane run unit tests.

#### `smf_linter`
This lane runs lint tasks like swift lint.

#### `smf_pipeline_danger`
[See Common Setup](#smf_pipeline_danger)

### Additional Lanes used for building

#### `smf_generate_changelog`
[See Common Setup](#smf_generate_changelog)

#### `smf_pipeline_increment_build_number`
[See Common Setup](#smf_pipeline_increment_build_number)

#### `smf_pipeline_create_git_tag`
[See Common Setup](#smf_pipeline_create_git_tag)

#### `smf_upload_dsyms`
This lane uploads the symbolication files to sentry. :arrow_up:

#### `smf_upload_to_appcenter`
This lane uploads the IPA to App Center if a `appcenter_id` is given for the build variant in the Config.json. :arrow_up:
```
 "live": {
       "variant": "productionRelease",
       "appcenter_id": "ExampleID"
     }
```
#### `smf_upload_to_itunes`
This lane uploads to app to Testflight. :arrow_up::airplane:

#### `smf_push_git_tag_release`
This lane pushes changes to GitHub using the created tag. Is also creates a GitHub release.

#### `smf_send_slack_notification`
[See Common Setup](#smf_send_slack_notification)






## Android App Setup

### Pull Request Lanes

#### `smf_setup_dependencies_pr_check`/`smf_setup_dependencies_build`
These lanes do nothing, yet. :grin: You could overwrite one to use Phraseapp. To get to know how have a look at the [example](#Example`). :wink:

#### `smf_pipeline_update_android_commons`
This lane updates the Android Commons and generates the Jenkins file if it was outdated.

#### `smf_build`
This lane builds the app and saves the apk. :floppy_disk: The Keystore will be pulled if the keystore folder is defined in the Config.json. To add a folder name just add `keystore` to the build variant config. :key:
```
"live": {
      "variant": "productionRelease",
      "keystore": "Example"
    }
```

#### `smf_run_unit_tests`
This lane usually runs junit tests.

#### `smf_linter`
This lane runs lint tasks like klint.

#### `smf_pipeline_danger`
[See Common Setup](#smf_pipeline_danger`)

### Additional Lanes used for building

#### `smf_generate_changelog`
[See Common Setup](#smf_generate_changelog)

#### `smf_pipeline_increment_build_number`
[See Common Setup](#smf_pipeline_increment_build_number)

#### `smf_pipeline_create_git_tag`
[See Common Setup](#smf_pipeline_create_git_tag)

#### `smf_upload_to_appcenter`
This lane uploads the apk to App Center if a `appcenter_id` is defined for the build variant Config.json. :arrow_up:
```
 "live": {
       "variant": "productionRelease",
       "keystore": "Example",
       "appcenter_id": "ExampleID"
     }
```

#### `smf_generate_changelog`
[See Common Setup](#smf_generate_changelog)

#### `smf_push_git_tag_release`
This lane pushes changes to GitHub using the created tag.

`smf_send_slack_notification`
[See Common Setup](#smf_send_slack_notification)






# Common Setup
In the following sections the common default Fastlane lanes for iOS and Android Apps will be explained. They are used both on iOS and Android.

### Fastlane Lanes
#### `smf_pipeline_increment_build_number`
This lane increments the build number. :chart_with_upwards_trend: To get the current build number, the last tag from GitHub will be fetched. If the build number in the project is greater than the number from GitHub it will be used.

#### `smf_pipeline_create_git_tag`
This lane creates a tag on GitHub which is build using the following pattern: *build/\<build variant\>/\<build number\>*.

#### `smf_generate_changelog`
This lane generates the changelog and saves it in a temporary file to be usually read for notifications e.g. on Slack. The changelog will be generates by looking for the last tag on Github, which contains the build variant which you build. The changes between the new build and the last one will be listed. :clipboard:

#### `smf_send_slack_notification`
This lanes sends the default build success notification to Slack. :envelope::white_check_mark:

#### `smf_pipeline_danger`
This lanes runs danger which will send the results from the lint tasks to GitHub. :rotating_light:




# Custom Behaviour

To add custom behaviour for your app you can simply overwrite the default lane in the Fastfile in your project. :wrench:

## Example
Use Phraseapp for iOS app.
```
override_lane :smf_setup_dependencies_build do | options |
  # call the default setup
  smf_super_setup_dependencies(options)

  # Add custom sync phrase app call
  phrase_app_properties = {
      :format           => "...",
      :access_token_key => "...",
      :project_id       => "...",
      :source           => "...",
      :locales          => [
          "...",
          "..."
      ],
      :base_directory   => "...",
      :files            => [
          "...",
          "..."
      ],
      :forbid_comments_in_source => true,                   # Optional, remove if not needed
      :files_prefix              => "...",                  # Optional, remove if not needed
      :git_branch                => options[:git_branch],   # Optional, leave options[:git_branch] as default value       
      :extensions                => [
          {
              :project_id       => "...",
              :base_directory   => "...",
              :files            => [
                  "...",
                  "..."
              ]
          }
      ]
  }
  
  smf_sync_with_phrase_app(phrase_app_properties)
end
```