# Get Started
This documentation helps you understand the Fastlane Commons which are used by Jenkins Pipeline Commons.

### Fastlane and Jenkins Pipeline Commons
To begin with, it is good to know how the Fastlane Commons and the Jenkins Pipeline Commons work together.

The Pipeline Commons contain seperated files for macOS Apps, iOS Apps and Frameworks and Android Apps and Frameworks. Each file contains stages to run on pull requests and builds. 

From every stage one specific Fastlane lane is called. Those lanes are defined in the corresponding setup file like *ios_setup.rb*.

Every specific lane in the setup files has a "super" lane recognizable by the `super` keyword. Why is that? :confused:
As mentioned before the specific lanes will be called directly from the stages in the Jenkins Pipeline Commons. You can think of them as default lanes. In most cases they just call their super lane. If you would like to modify these default lanes you would often like to call the super lane with different parameters. 

To learn how to overwrite the default lanes to customize your build process have a look at the *Custom Behaviour* section.

**For every lane there is a README.** To see how each lane acts and what parameter it needs have a look at it. How to find it: In the SMF-Fastlane-Commons Repository you can find a directory called "commons". For each lane an equally named directory exists which contains the expected README. If you can not find the directory you are looking for search for it in the subdirectories "ios" and "android". 

Table of Contents
=================

   * [Get Started](#get-started)
        * [Fastlane and Jenkins Pipeline Commons](#fastlane-and-jenkins-pipeline-commons)
   * [Table of Contents](#table-of-contents)
   * [Common Setup](#common-setup)
        * [Fastlane Lanes](#fastlane-lanes)
            * [smf_pipeline_danger](#smf_pipeline_danger)
            * [smf_generate_changelog](#smf_generate_changelog)
            * [smf_pipeline_increment_build_number](#smf_pipeline_increment_build_number)
            * [smf_pipeline_create_git_tag](#smf_pipeline_create_git_tag)
            * [smf_send_slack_notification](#smf_send_slack_notification)
   * [Platform Specific Setup](#platform-specific-setup)
      * [iOS App Setup](#ios-app-setup)
         * [Pull Request Lanes](#pull-request-lanes)
            * [smf_generate_files](#smf_generate_files)
            * [smf_setup_dependencies_pr_check/smf_setup_dependencies_build](#smf_setup_dependencies_pr_checksmf_setup_dependencies_build)
            * [smf_build](#smf_build)
            * [smf_unit_tests](#smf_unit_tests)
            * [smf_linter](#smf_linter)
            * [smf_pipeline_danger](#smf_pipeline_danger-1)
         * [Additional Lanes used for building](#additional-lanes-used-for-building)
            * [smf_generate_changelog](#smf_generate_changelog-1)
            * [smf_pipeline_increment_build_number](#smf_pipeline_increment_build_number-1)
            * [smf_pipeline_create_git_tag](#smf_pipeline_create_git_tag-1)
            * [smf_upload_dsyms](#smf_upload_dsyms)
            * [smf_upload_to_appcenter](#smf_upload_to_appcenter)
            * [smf_upload_to_itunes](#smf_upload_to_itunes)
            * [smf_push_git_tag_release](#smf_push_git_tag_release)
            * [smf_send_slack_notification](#smf_send_slack_notification-1)
      * [Android App Setup](#android-app-setup)
         * [Pull Request Lanes](#pull-request-lanes-1)
            * [smf_setup_dependencies_pr_check/smf_setup_dependencies_build](#smf_setup_dependencies_pr_checksmf_setup_dependencies_build-1)
            * [smf_pipeline_update_android_commons](#smf_pipeline_update_android_commons)
            * [smf_build](#smf_build-1)
            * [smf_run_unit_tests](#smf_run_unit_tests)
            * [smf_linter](#smf_linter-1)
            * [smf_pipeline_danger](#smf_pipeline_danger-2)
         * [Additional Lanes used for building](#additional-lanes-used-for-building-1)
            * [smf_generate_changelog](#smf_generate_changelog-2)
            * [smf_pipeline_increment_build_number](#smf_pipeline_increment_build_number-2)
            * [smf_pipeline_create_git_tag](#smf_pipeline_create_git_tag-2)
            * [smf_upload_to_appcenter](#smf_upload_to_appcenter-1)
            * [smf_generate_changelog](#smf_generate_changelog-3)
            * [smf_push_git_tag_release](#smf_push_git_tag_release-1)
            * [smf_send_slack_notification](#smf_send_slack_notification-2)
      * [Flutter App Setup](#flutter-app-setup)
         * [Pull Request Lanes](#pull-request-lanes-2)
            * [smf_generate_files](#smf_generate_files-1)
            * [smf_shared_setup_dependencies_pr_check/smf_setup_dependencies_build](#smf_shared_setup_dependencies_pr_checksmf_setup_dependencies_build)
            * [smf_ios_build](#smf_ios_build)
            * [smf_android_build](#smf_android_build)
            * [smf_linter](#smf_linter-2)
            * [smf_run_unit_tests](#smf_run_unit_tests-1)
            * [smf_shared_pipeline_danger](#smf_shared_pipeline_danger)
         * [Additional Lanes used for building](#additional-lanes-used-for-building-2)
            * [smf_generate_changelog](#smf_generate_changelog-4)
            * [smf_pipeline_increment_build_number](#smf_pipeline_increment_build_number-3)
            * [smf_pipeline_create_git_tag](#smf_pipeline_create_git_tag-3)
            * [smf_upload_dsyms](#smf_upload_dsyms-1)
            * [smf_pipeline_ios_upload_to_appcenter](#smf_pipeline_ios_upload_to_appcenter)
            * [smf_pipeline_android_upload_to_appcenter](#smf_pipeline_android_upload_to_appcenter)
            * [smf_upload_to_itunes](#smf_upload_to_itunes-1)
            * [smf_push_git_tag_release](#smf_push_git_tag_release-2)
            * [smf_send_slack_notification](#smf_send_slack_notification-3)
      * [macOS App Setup](#macos-app-setup)
         * [Pull Request Lanes](#pull-request-lanes-3)
            * [smf_generate_files](#smf_generate_files-2)
            * [smf_setup_dependencies_pr_check/smf_setup_dependencies_build](#smf_setup_dependencies_pr_checksmf_setup_dependencies_build-2)
            * [smf_build](#smf_build-2)
            * [smf_unit_tests](#smf_unit_tests-1)
            * [smf_linter](#smf_linter-3)
            * [smf_pipeline_danger](#smf_pipeline_danger-3)
         * [Additional Lanes used for building](#additional-lanes-used-for-building-3)
            * [smf_generate_changelog](#smf_generate_changelog-5)
            * [smf_pipeline_increment_build_number](#smf_pipeline_increment_build_number-4)
            * [smf_pipeline_create_git_tag](#smf_pipeline_create_git_tag-4)
            * [smf_create_dmg_and_gatekeeper](#smf_create_dmg_and_gatekeeper)
            * [smf_upload_dsyms](#smf_upload_dsyms-2)
            * [smf_pipeline_upload_with_sparkle](#smf_pipeline_upload_with_sparkle)
            * [smf_upload_to_appcenter](#smf_upload_to_appcenter-2)
            * [smf_push_git_tag_release](#smf_push_git_tag_release-3)
            * [smf_send_slack_notification](#smf_send_slack_notification-4)
   * [Custom Behaviour](#custom-behaviour)
      * [Example](#example)
      
# Common Setup
In the following section the common default Fastlane lanes for Flutter, macOS, iOS and Android Apps will be explained. They are used for all platforms and behave in the exact same way. To see the specific behaviour of a lane have a look at the platform's section.

### Fastlane Lanes


#### `smf_pipeline_danger`
This lane runs danger which will send the results from the lint tasks to GitHub. :rotating_light:

#### `smf_generate_changelog`
This lane generates the changelog and saves it in a temporary file to be usually read for notifications e.g. on Slack. The changelog will be generated by looking for the last tag on Github, which contains the build variant that you build. The changes between the new build and the last one will be listed. :clipboard:

#### `smf_pipeline_increment_build_number`
This lane increments the build number. :chart_with_upwards_trend: To get the current build number, the last tag from GitHub will be fetched. If the build number in the project is greater than the number from GitHub it will be used.

#### `smf_pipeline_create_git_tag`
This lane creates a tag on GitHub which is build using the following pattern: *build/\<build variant\>/\<build number\>*.

#### `smf_send_slack_notification`
This lane sends the default build success notification to Slack. :envelope::white_check_mark:
      
      
      
      
# Platform Specific Setup
In the following sections the default lanes for each platform will be explained. These are the lanes called for checking pull requests and builds.

For each platform they are ordered by the following criteria:
1. PR lanes before build lanes
2. Lanes that are only called during builds are chronologically arranged

## iOS App Setup

### Pull Request Lanes

#### `smf_generate_files`
This lane generates the Jenkinsfile if it was outdated. If there are other files which should be generated, you can overwrite this lane.

#### `smf_setup_dependencies_pr_check`/`smf_setup_dependencies_build`
These lanes install pods if a podfile is present in the project. They also check multiple properties (duplicated build numbers, is there an editable app version, etc.) to reduce the risk of errors when uploading to iTunes Connect. For this check `upload_itc` must be set to true in the Config.json. There is one lane for PR-Checks and one for Builds to be able to only run code for one of the two. For example Phrase-App should only be called during a build. To get to know how, have a look at the [example](#Example`). :wink:

#### `smf_build`
This lane downloads the provisioning profiles and builds the app and saves the IPA. :floppy_disk:

#### `smf_unit_tests`
This lane run unit tests.

#### `smf_linter`
This lane runs lint tasks like swift lint.

#### `smf_pipeline_danger`
[See this lane in Common Setup](#smf_pipeline_danger)

### Additional Lanes used for building

#### `smf_generate_changelog`
[See this lane in Common Setup](#smf_generate_changelog)

#### `smf_pipeline_increment_build_number`
[See this lane in Common Setup](#smf_pipeline_increment_build_number)

#### `smf_pipeline_create_git_tag`
[See this lane in Common Setup](#smf_pipeline_create_git_tag)

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
This lane uploads the app to Testflight. :arrow_up::airplane:

#### `smf_push_git_tag_release`
This lane pushes changes to GitHub using the created tag. Is also creates a GitHub release.

#### `smf_send_slack_notification`
[See this lane in Common Setup](#smf_send_slack_notification)




## Android App Setup

### Pull Request Lanes

#### `smf_setup_dependencies_pr_check`/`smf_setup_dependencies_build`
These lanes do nothing, yet. :grin: You could overwrite one to use Phraseapp. To get to know how, have a look at the [example](#Example`). :wink:

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
[See this lane in Common Setup](#smf_pipeline_danger)

### Additional Lanes used for building

#### `smf_generate_changelog`
[See this lane in Common Setup](#smf_generate_changelog)

#### `smf_pipeline_increment_build_number`
[See this lane in Common Setup](#smf_pipeline_increment_build_number)

#### `smf_pipeline_create_git_tag`
[See this lane in Common Setup](#smf_pipeline_create_git_tag)

#### `smf_upload_to_appcenter`
This lane uploads the apk to App Center if a `appcenter_id` is defined for the build variant Config.json. :arrow_up:
```
 "live": {
       "variant": "productionRelease",
       "keystore": "Example",
       "appcenter_id": "ExampleID"
     }
```

#### `smf_push_git_tag_release`
This lane pushes changes to GitHub using the created tag.

#### `smf_send_slack_notification`
[See this lane in Common Setup](#smf_send_slack_notification)




## Flutter App Setup

### Pull Request Lanes

#### `smf_generate_files`
This lane generates the Jenkinsfile if it was outdated. If there are other files which should be generated, you can overwrite this lane.

#### `smf_shared_setup_dependencies_pr_check`/`smf_setup_dependencies_build`
These lanes install pods if a podfile is present and execute `sh generate.sh` in the project. They also check multiple properties (duplicated build numbers, is there an editable app version, etc.) to reduce the risk of errors when uploading to iTunes Connect. For this check `upload_itc` must be set to true in the Config.json. There is one lane for PR-Checks and one for Builds to be able to only run code for one of the two. For example Phrase-App should only be called during a build. To get to know how, have a look at the [example](#Example`). :wink:

#### `smf_ios_build`
This lane downloads the provisioning profiles and builds the iOS App of the flutter project by first building the App via flutter command `build ios` and building it as a default iOS app afterwards.

#### `smf_android_build`
This lane builds the Android app of the flutter project by using the flutter command `build apk` and saves the apk. :floppy_disk: The Keystore will be pulled if the keystore folder is defined in the Config.json. To add a folder name just add `keystore` to the build variant config. :key:
```
"variant": "productionRelease",
"live": {
"keystore": "Example"
}
```

#### `smf_linter`
This lane executes the flutter command `analyze` to analyze the code.

#### `smf_run_unit_tests`
This lane runs flutter unit tests by using flutter command `test`.

#### `smf_shared_pipeline_danger`
[See this lane in Common Setup](#smf_pipeline_danger)

### Additional Lanes used for building

#### `smf_generate_changelog`
[See this lane in Common Setup](#smf_generate_changelog)

#### `smf_pipeline_increment_build_number`
[See this lane in Common Setup](#smf_pipeline_increment_build_number)

#### `smf_pipeline_create_git_tag`
[See this lane in Common Setup](#smf_pipeline_create_git_tag)

#### `smf_upload_dsyms`
This lane uploads the symbolication files to sentry. :arrow_up:

#### `smf_pipeline_ios_upload_to_appcenter`
This lane uploads the IPA to AppCenter. :arrow_up:

#### `smf_pipeline_android_upload_to_appcenter`
This lane uploads the APK to AppCenter. :arrow_up:

#### `smf_upload_to_itunes`
This lane uploads the app to Testflight. :arrow_up::airplane:

#### `smf_push_git_tag_release`
This lane pushes changes to GitHub using the created tag. It also creates a GitHub release.

#### `smf_send_slack_notification`
[See this lane in Common Setup](#smf_send_slack_notification)




## macOS App Setup

### Pull Request Lanes

#### `smf_generate_files`
This lane generates the Jenkinsfile if it was outdated. If there are other files which should be generated, you can overwrite this lane.

#### `smf_setup_dependencies_pr_check`/`smf_setup_dependencies_build`
These lanes install pods if a podfile is present in the project. There is one lane for PR-Checks and one for Builds to be able to only run code for one of the two. For example Phrase-App should only be called during a build. To get to know how, have a look at the [example](#Example`). :wink:

#### `smf_build`
This lane builds the macOS app.

#### `smf_unit_tests`
This lane runs the unit tests.

#### `smf_linter`
This lane runs lint tasks like swift lint.

#### `smf_pipeline_danger`
[See this lane in Common Setup](#smf_pipeline_danger)

### Additional Lanes used for building

#### `smf_generate_changelog`
[See this lane in Common Setup](#smf_generate_changelog)

#### `smf_pipeline_increment_build_number`
[See this lane in Common Setup](#smf_pipeline_increment_build_number)

#### `smf_pipeline_create_git_tag`
[See this lane in Common Setup](#smf_pipeline_create_git_tag)

#### `smf_create_dmg_and_gatekeeper`
This lane creates the dmg from the app and notarizes it if `notarize` is set to true in the build variant config in the Config.json.

#### `smf_upload_dsyms`
This lane uploads the dsyms to sentry.

#### `smf_pipeline_upload_with_sparkle`
This lane uploads the dmg with sparkle.

#### `smf_upload_to_appcenter`
This lane uploads the dmg to AppCenter.

#### `smf_push_git_tag_release`
This lane pushes changes to GitHub using the created tag. It also creates a GitHub release.

#### `smf_send_slack_notification`
[See this lane in Common Setup](#smf_send_slack_notification)

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