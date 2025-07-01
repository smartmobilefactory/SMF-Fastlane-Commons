# smf_upload_with_sparkle

This lane prepares a Sparkle package containing:
- App's DMG
- An HTML file containing the changelog
- XML file containing update informations called appcast. It contains hardcoded URLs for the DMG and the changelog.

If `sparkle_upload_user` and `sparkle_upload_url` are specified, the package will be uploaded via `scp` to the specified location.

## Application configuration

On top of the configuration in Config.json, one needs to specify information in the Info.plist for the package to be created.
See documentation for more details: https://sparkle-project.org/documentation/

- `SUPublicEDKey`: Should contain the public part of the EdDSA signature used to sign the update.
- `SUFeedURL`: URL where the app will look for the appcast.xml file. This URL is used as a base to generate the URLs inside appcast.xml. For example, if the URL is https://example.com/update/appcast.xml, then the DMG and the changelog will also be in https://example.com/update/

### Optional keys:

- `SMFSUAlternativeFeedURL`: This is a SMF custom key that allows us to specify a second update URL. If the value for this key is a valid URL, then a second Sparkle package will be created as a child of the main one, in a sub-folder named `test` (customer requirement). If the value is not a valid URL, or the key does not exist, then the second package won't be created. See https://sosimple.atlassian.net/browse/STRMAC-2306.

## Example
Uploads the .dmg to Sparkle.

```
smf_upload_with_sparkle(
    build_variant: "alpha",                     # The currently building build variant
    create_intermediate_folder: <bool>          # Optional (defaults to false): If true, the package will be uploaded in a release specific folder (Used to upload pre-releases). If false, it will be uploaded directly in `sparkle_upload_url.sparkle_dmg_path`
    scheme: <scheme>,                         
    sparkle_dmg_path: <path to file>,           # Optional: the Path to the .dmg file, needed for upload
    sparkle_upload_user: <>,                    # Optional: needed for upload
    sparkle_upload_url: <>,                     # Optional: needed for upload
    sparkle_version: <>,
    sparkle_signing_team: <>,
    sparkle_xml_name: <>,
    sparkle_private_key: <>
    source_dmg_path: <path to custom .dmg>                      # Optional see section "Sparkle Package Creator"
    target_directory: <directory where to store the appcast>    # Optional see section "Sparkle Package Creator"
)
``` 
### Sparkle Package Creator
This lane is also used by the sparkle package creator tool. Therefore the upload url and user are set to nil to prevent the lane from uploading. A custom source path for the app's dmg is given. The appcast, html etc is then created at the given target directory. 

We need this package creator to be able to create a Sparkle package after Telekom sent us the signed version of their app. https://sosimple.atlassian.net/l/c/G71YsTQm
Our regular build process is able to make a Sparkle package starting from source code, with this `Sparkle package creator`, we can directly make a package from an already existing DMG.

- Package creator URL: https://ci.smfhq.com/job/HiDrive_App/job/Sparkle-Package-Creator_iOS/
- In any case, the packages created via this method are stored as a release in this repo: https://github.com/smartmobilefactory/SMF-Sparkle-Packages-Container


### Custom Sparkle Credentials for MacOS-Apps

If you want to add a custom Credential for the sparkle upload, follow these steps:
1. Add the credential in Jenkins, give it a meaningful name. For this tutorial Lets say you named it `new_jenkins_credential_key`.
2. In the Config.json in the `project.custom_credentials` section add the following entry:

```
{
    "project" : {
        ...,
        "custom_credentials": {
            ..., 
            "<env_variable_name_for_credential>": {                         \
                "jenkins_credential_name" : "new_jenkins_credential_key",   |____ this section should be added
                "type" : "<credential type>"                                |       # type is optional and defaults to 'string'
            },                                                              /
    },
    "build_variants" : { ... }
}
```
 `<env_variable_name_for_credential>` will be the name of the env variable in which the credential will be stored during runtime to be used by fastlane.
 
 **Type**:
  The type is optional and defaults to `string`. So in the most cases you don't have to add the type field. There are (so far) two possible crendential types:
  
  | Type | Description |
  | :---: | :--- |
  | "string"| The credential is a simple string, a API-Token for example. You want to use this in the most of the cases. |
  | "file"  | The credential is stored in a file, for example an ssh key. |

    
 3. In each build variant which should use the newly added credential as sparkle key do the following: In the build variants `sparkle` section add the environment variable name (`<env_variable_name_for_credential>`  from step two) as `signing_key`. Like this:
 
```
{
   "project" : {
       ...,
       "custom_credentials": {
           ..., 
           "<env_variable_name_for_credential>": {      
               "name" : "new_jenkins_credential_key",   
               "type" : "<credential type>"             # Optional          
           },                                          
   },
   "build_variants" : { 
       ...,
       "your_build_variant" : {
            ...,
            "sparkle" : {
                "signing_key" : "<env_variable_name_for_credential>",      # insert the env key name here
                ...
            }
       }
   }
}
```

Now your all done 🎉. When building the edited build variant, fastlane will use the added credential 👏.

#### Custom Credential Example
Lets say you added the following token in Jenkins as a credential:

PARTY_API_TOKEN = "e58f98ab80c98d98e"

Config.json:

```
{
   "project" : {
       ...,
       "custom_credentials": {
           ..., 
           "PARTY_API_TOKEN_KEY": {      
               "name" : "PARTY_API_TOKEN"           # Note: tpye is not specified because it defaults to string     
           },                                          
   },
   "build_variants" : { 
       ...,
       "your_party_build_variant" : {
            ...,
            "sparkle" : {
                "signing_key" : "PARTY_API_TOKEN_KEY",
                ...
            }
       }
   }
}
```

Now your all set 🎉 Party hard 🥳