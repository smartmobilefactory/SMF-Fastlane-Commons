# iOS Lane Documentation

### Setup Dependencies

The lane `smf_setup_dependencies` handles dependecy setup. By default it calls its super lane which does the following things:
##### [smf_pod install](../commons/ios/smf_pod_install/smf_pod_install.rb)
- installs all pod listed in the projects podfile

##### [smf_verify_itc_upload_errors](../commons/ios/smf_verify_itc_upload_errors/smf_verify_itc_upload_errors.rb)
- Checks for possible errors that could occure during an iTunes Connect Upload
- This check is only executed if `upload_itc` is set to true in the Config.json

#### Optional Calls

[smf_sync_with_phrase_app](../commons/smf_sync_with_phrase_app/smf_sync_with_phrase_app.rb)
- Synchronises localized strings with Phrase-App
- If you want to enable Phrase-App synchronisation for the project, you have to override the `smf_setup_dependency` lane in the proejcts fastfile

Steps:
 
1. Add the following code to your projects Fastfile
```
override_lane :smf_setup_dependencies do | options |
  # call the default setup
  smf_super_setup_dependencies(options)

  # Add custom sync phrase app call
  phrase_app_properties = {
      "format" : "...",
      "access_token_key" : "...",
      "project_id" : "...",
      "source" : "...",
      "locales" : [
          "...",
          "..."
      ],
      "base_directory" : "...",
      "files" : [
          "...",
          "..."
      ],
      "forbid_comments_in_source" : false/true,
      "files_prefix" : "...",
      "git_branch" : "...",
      "extensions" : [
          {
              "project_id" : "...",
              "base_directory" : "...",
              "files" : [
                  "...",
                  "..."
              ]
          }
      ]
  }
  
  smf_sync_with_phrase_app(phrase_app_properties)
end
```
        