# Get Started
This documentation helps you understand the Fastlane Commons which are used by Jenkins Pipeline Commons.

### Fastlane and Jenkins Pipeline Commons
To begin with, it is good to know how the Fastlane Commons and the Jenkins Pipeline Commons work together.

The Pipeline Commons contain separated files for macOS Apps, iOS Apps, Android apps and iOS and Android Frameworks. Each file contains stages to run on pull requests and builds. 

From every stage one specific Fastlane lane is called. Those lanes are defined in the corresponding setup file like *ios_setup.rb*.

Every specific lane in the setup files has a "super" lane recognizable by the `super` keyword. Why is that? :confused:
As mentioned before the specific lanes will be called directly from the stages in the Jenkins Pipeline Commons. You can think of them as default lanes. In most cases they just call their super lane. If you would like to modify these default lanes you would often like to call the super lane with different parameters. 

To learn how to overwrite the default lanes to customize your build process have a look at the *Custom Behaviour* section.

**For every lane there is a README.** To see how each lane acts and what parameters it needs, have a look at it. How to find it: In the SMF-Fastlane-Commons Repository you can find a directory called "commons". For each lane an equally named directory exists which contains the expected README. If you can not find the directory you are looking for search for it in the subdirectories "ios" and "android". 

Table of Contents
=================

   - [Get Started](#get-started)
       + [Fastlane and Jenkins Pipeline Commons](#fastlane-and-jenkins-pipeline-commons)
   - [Common Setup](#common-setup)
       + [Fastlane Lanes](#fastlane-lanes)
         - [`smf_pipeline_danger`](#-smf-pipeline-danger-)
         - [`smf_generate_changelog`](#-smf-generate-changelog-)
         - [`smf_pipeline_increment_build_number`](#-smf-pipeline-increment-build-number-)
         - [`smf_pipeline_create_git_tag`](#-smf-pipeline-create-git-tag-)
         - [`smf_send_slack_notification`](#-smf-send-slack-notification-)
   - [Platform Specific Setup](#platform-specific-setup)
     * [iOS App Setup](#ios-app-setup)
       + [Pull Request Lanes](#pull-request-lanes)
         - [`smf_generate_files`](#-smf-generate-files-)
         - [`smf_setup_dependencies_pr_check`/`smf_setup_dependencies_build`](#-smf-setup-dependencies-pr-check---smf-setup-dependencies-build-)
         - [`smf_build`](#-smf-build-)
         - [`smf_unit_tests`](#-smf-unit-tests-)
         - [`smf_linter`](#-smf-linter-)
         - [`smf_pipeline_danger`](#-smf-pipeline-danger--1)
       + [Additional Lanes used for building](#additional-lanes-used-for-building)
         - [`smf_generate_changelog`](#-smf-generate-changelog--1)
         - [`smf_pipeline_increment_build_number`](#-smf-pipeline-increment-build-number--1)
         - [`smf_pipeline_create_git_tag`](#-smf-pipeline-create-git-tag--1)
         - [`smf_upload_dsyms`](#-smf-upload-dsyms-)
         - [`smf_upload_to_itunes`](#-smf-upload-to-itunes-)
         - [`smf_push_git_tag_release`](#-smf-push-git-tag-release-)
         - [`smf_send_slack_notification`](#-smf-send-slack-notification--1)
     * [iOS Framework Setup](#ios-framework-setup)
       + [Reporting Lanes](#reporting-lanes)
         - [`smf_pod_super_reporting`](#-smf-pod-super-reporting-)
     * [Apple App Setup](#apple-app-setup)
       + [Pull Request Lanes](#pull-request-lanes-1)
         - [`smf_generate_files`](#-smf-generate-files--1)
         - [`smf_setup_dependencies_pr_check`/`smf_setup_dependencies_build`](#-smf-setup-dependencies-pr-check---smf-setup-dependencies-build--1)
         - [`smf_build`](#-smf-build--1)
         - [`smf_unit_tests`](#-smf-unit-tests--1)
         - [`smf_linter`](#-smf-linter--1)
         - [`smf_pipeline_danger`](#-smf-pipeline-danger--2)
       + [Additional Lanes used for building](#additional-lanes-used-for-building-1)
         - [`smf_generate_changelog`](#-smf-generate-changelog--2)
         - [`smf_pipeline_increment_build_number`](#-smf-pipeline-increment-build-number--2)
         - [`smf_pipeline_create_git_tag`](#-smf-pipeline-create-git-tag--2)
         - [`smf_create_dmg_and_gatekeeper`](#-smf-create-dmg-and-gatekeeper-)
         - [`smf_upload_dsyms`](#-smf-upload-dsyms--1)
         - [`smf_pipeline_upload_with_sparkle`](#-smf-pipeline-upload-with-sparkle-)
         - [`smf_upload_to_itunes`](#-smf-upload-to-itunes--1)
         - [`smf_push_git_tag_release`](#-smf-push-git-tag-release--1)
         - [`smf_send_slack_notification`](#-smf-send-slack-notification--2)
     * [Android App Setup](#android-app-setup)
       + [Pull Request Lanes](#pull-request-lanes-2)
         - [`smf_setup_dependencies_pr_check`/`smf_setup_dependencies_build`](#-smf-setup-dependencies-pr-check---smf-setup-dependencies-build--2)
         - [`smf_build`](#-smf-build--2)
         - [`smf_run_unit_tests`](#-smf-run-unit-tests-)
         - [`smf_linter`](#-smf-linter--2)
         - [`smf_pipeline_danger`](#-smf-pipeline-danger--3)
       + [Additional Lanes used for building](#additional-lanes-used-for-building-2)
         - [`smf_generate_changelog`](#-smf-generate-changelog--3)
         - [`smf_pipeline_increment_build_number`](#-smf-pipeline-increment-build-number--3)
         - [`smf_pipeline_create_git_tag`](#-smf-pipeline-create-git-tag--3)
         - [`smf_push_git_tag_release`](#-smf-push-git-tag-release--2)
         - [`smf_send_slack_notification`](#-smf-send-slack-notification--3)
     * [Flutter App Setup](#flutter-app-setup)
       + [Pull Request Lanes](#pull-request-lanes-3)
         - [`smf_generate_files`](#-smf-generate-files--2)
         - [`smf_shared_setup_dependencies_pr_check`/`smf_setup_dependencies_build`](#-smf-shared-setup-dependencies-pr-check---smf-setup-dependencies-build-)
         - [`smf_ios_build`](#-smf-ios-build-)
         - [`smf_android_build`](#-smf-android-build-)
         - [`smf_linter`](#-smf-linter--3)
         - [`smf_run_unit_tests`](#-smf-run-unit-tests--1)
         - [`smf_shared_pipeline_danger`](#-smf-shared-pipeline-danger-)
       + [Additional Lanes used for building](#additional-lanes-used-for-building-3)
         - [`smf_generate_changelog`](#-smf-generate-changelog--4)
         - [`smf_pipeline_increment_build_number`](#-smf-pipeline-increment-build-number--4)
         - [`smf_pipeline_create_git_tag`](#-smf-pipeline-create-git-tag--4)
         - [`smf_upload_dsyms`](#-smf-upload-dsyms--2)
         - [`smf_upload_to_itunes`](#-smf-upload-to-itunes--2)
         - [`smf_push_git_tag_release`](#-smf-push-git-tag-release--3)
         - [`smf_send_slack_notification`](#-smf-send-slack-notification--4)
     * [macOS App Setup](#macos-app-setup)
       + [Pull Request Lanes](#pull-request-lanes-4)
         - [`smf_generate_files`](#-smf-generate-files--3)
         - [`smf_setup_dependencies_pr_check`/`smf_setup_dependencies_build`](#-smf-setup-dependencies-pr-check---smf-setup-dependencies-build--3)
         - [`smf_build`](#-smf-build--3)
         - [`smf_unit_tests`](#-smf-unit-tests--2)
         - [`smf_linter`](#-smf-linter--4)
         - [`smf_pipeline_danger`](#-smf-pipeline-danger--4)
       + [Additional Lanes used for building](#additional-lanes-used-for-building-4)
         - [`smf_generate_changelog`](#-smf-generate-changelog--5)
         - [`smf_pipeline_increment_build_number`](#-smf-pipeline-increment-build-number--5)
         - [`smf_pipeline_create_git_tag`](#-smf-pipeline-create-git-tag--5)
         - [`smf_create_dmg_and_gatekeeper`](#-smf-create-dmg-and-gatekeeper--1)
         - [`smf_upload_dsyms`](#-smf-upload-dsyms--3)
         - [`smf_pipeline_upload_with_sparkle`](#-smf-pipeline-upload-with-sparkle--1)
         - [`smf_push_git_tag_release`](#-smf-push-git-tag-release--4)
         - [`smf_send_slack_notification`](#-smf-send-slack-notification--5)
   - [Custom Behaviour](#custom-behaviour)
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
This lane runs unit tests.

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

#### `smf_upload_to_itunes`
This lane uploads the app to Testflight. :arrow_up::airplane:

#### `smf_push_git_tag_release`
This lane pushes changes to GitHub using the created tag. Is also creates a GitHub release.

#### `smf_send_slack_notification`
[See this lane in Common Setup](#smf_send_slack_notification)

## iOS Framework Setup

### Reporting Lanes

#### `smf_pod_super_reporting`

This lane is used by reporting jenkins jobs to upload unit test results to a google spread sheet.


## Apple App Setup

The Apple app setup is use for iOS-Apps which are catalyst enabled. This means they can be build for iOS as well as macOS. Thus for those projects the `@platform` variable is set to `:apple`. If a project is catalyst enabled, the build variants which support macOS build needs the following `alt_platforms` entry in the Config.json:
```
...
"alpha": {
    "scheme"				: "Example-Scheme",
    "apple_id"				: "...",
    "bundle_identifier"		: "...",
    ...
    "alt_platforms" : {
        "macOS": {
            "code_signing_identity"	: "<code siginig identity for the macOS build of this build variant>",
            "upload_itc"			: false,
            "notarize"				: true,
            "match": {
                "read_only"			: false,
                "type"				: "developer_id"
            },
            ....
        }
    }
},
```
For each build_variant where an 'alt_platforms-macos' entry exists, the additional build_variant `macOS_<build_variant>` is generated into the projects jenkins file. To build a macOS version simply select the `macOS_` prefixed build variant. Furthermore for the macOS build variant the config.json values are first taken from the 'alt_platform' entry, if they can't be found there, the values from the normal build variant are taken.
### Pull Request Lanes

#### `smf_generate_files`
This lane generates the Jenkinsfile if it was outdated. If there are other files which should be generated, you can overwrite this lane.

#### `smf_setup_dependencies_pr_check`/`smf_setup_dependencies_build`
These lanes install pods if a podfile is present in the project. They also check multiple properties (duplicated build numbers, is there an editable app version, etc.) to reduce the risk of errors when uploading to iTunes Connect. For this check `upload_itc` must be set to true in the Config.json. There is one lane for PR-Checks and one for Builds to be able to only run code for one of the two. For example Phrase-App should only be called during a build. To get to know how, have a look at the [example](#Example`). :wink:

#### `smf_build`
This lane downloads the provisioning profiles and builds the app and saves the IPA/App. :floppy_disk:

#### `smf_unit_tests`
This lane runs unit tests.

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
This lane uploads the symbolication files to sentry. :arrow_up:

#### `smf_pipeline_upload_with_sparkle`
This lane uploads the dmg with sparkle.

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