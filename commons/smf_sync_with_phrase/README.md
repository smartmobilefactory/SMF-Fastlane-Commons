# Phrase Synchronisation

## Overview

The fastlane lane `smf_sync_with_phrase` can be used to synchronize localizables with phrase.

How this generally works is, we have a default language (android -> default, ios -> base). All localizable/string files from this language are uploaded to phrase (during the upload phase). This way newly added key-values pairs are added to phrase. This does **NOT** override already existings keys-values with new values.

During the download phase, the key-value pairs present in phrase are downloaded into the corresponding files.

## Commons Parameters

| Parameter     | Type          | Required  | Description |
|:------------- |:------------- |:--------- |:----------- |
|project_id|String|true|The projects id from phrase. Looks like: 123cdef123456abcd32ef34bg234eb|
|resource_dir|String|**android**: false <br> **ios**: true|The directory in which the resources of the projects are located (e.g. the values folder).<br><br> **Android**: This defaults to `/app/src/main/res/` for normal android projects and to `/core/src/commonMain/resources/MR/` for kmpp projects. The paths have to be relative to the projects root directory. Normally this doesn't need to be set.<br><br> **iOS**: The directory (relative to the projects root directory) which contains the folders with the differen locales.|
|upload_resource_dir|String|false|For this parameter you can pass in a path to a folder which contains the file you want to upload to phrase.<br><br> **Android**: For normal android projects this defaults to `resource_dir` + `values`. For kmpp projects this defaults to `resource_dir` + `base`.  The paths have to be relative to the projects root directory.<br><br> **iOS**: For iOS projects this defaults to `resource_dir` + `base_locale.lproj` where `base_locale` is the value which is passed in the `base` parameter (see iOS specific parameters for more details on `base`).<br><br>Set this if your files to upload are located in a different directory.|
|download_resource_dir|String|false|For this parameter you can pass in a path to a folder in which the subfolders for the different languages are located (or will be created). This defaults to the `resource_dir`. The paths have to be relative to the projects root directory.| 
|languages|Hash|true|This is a Hash (see Languages Hash Examples for the specific platform) which maps the languages to their corresponding phrase_ids.|

## Platform Specific Details

### Android

For Android there are two cases to consider, a **kmpp** project and a normal project.

#### Android Specific Parameters

| Parameter     | Type          | Required  | Description |
|:------------- |:------------- |:--------- |:----------- |
|is_kmpp|Bool|false|Needs to be set to true if the project is a kmpp project.|

Languages Hash Example:
```
{
    'default' => 'abcedf123456abcedfe13426ebdac',
    'de' => '125aae89d4a51461c45200ff72baf764',
    ...
}
```

The `default` language is the one who's key-value pairs will be uploaded to phrase.

### iOS

| Parameter     | Type          | Required  | Description |
|:------------- |:------------- |:--------- |:----------- |
|use_custom_api_token|Bool|false|If there is a custom api token set in the config.json for phraseapp, set this to true to use it.|
|base|String|true|The base locale which is uploaded to phrase. This can either be 'base' or any other commonly known locale (e.g. 'de', 'fr', 'en', ..)|
|extensions|Array|false|An array with a maps of extensions, see 'Extensions' section below for more details.|

##### Languages Hash Example:
The locale which is passed in the `base` parameter is the one we upload to phrase. This value needs to be set as key in the languages map with the corresponding locale_id as value.

Example if `base` is set to 'base':

```
{
    'base' => 'abcedf123456abcedfe13426ebdac',
    'de' => '125aae89d4a51461c45200ff72baf764',
    ...
}
```

Example if `base` is set to some other locale for example 'en':

```
{
    'en' => 'abcedf123456abcedfe13426ebdac',
    'de' => '125aae89d4a51461c45200ff72baf764',
    ...
}
```

##### Extensions

If an iOS project has extensions which contain Localizable files which should be synced with phrase, too, this can be achieved by passing the following structure to the lane for the `extensions` option.

###### Structure:
```
[
    {
          :project_id => "1234edfad2375dcd868acac678",
          :resource_dir => "Extensions/Phraseapp-Example",
          :languages => {
            'en' => '5d9a40634abc345efd5fa05ba95146b9',
            'de' => '2e1ced4312abe23def29b6dd4420ae6a'
          }
    }
]
```

The `project_id` has to be set to the phrase project id of the extension. The `resource_dir` should be the path from the projects root directory to the folder which contains the locale folders. Finally the `languages` map is structurally the same as the one for the main project, but has to be filled with the extension specific locale ids. As base language, the same locale is used that is passed in the `base` parameter for the main projects.

##### Encodings

For iOS, we try to convert the locale file to UTF-8 encoding to prevent wrong interpretation by phrase if the file has a unordinary encoding.  


### Deprecated Lane `smf_sync_with_phrase_app`

The lane `smf_sync_with_phrase_app` is deprecated. It is kept in the commons for backwards compatibility. If used it sends a deprecation warning to the projects slack channel with a link to a migration [guide](https://sosimple.atlassian.net/wiki/spaces/SMFCI/pages/2150498338/PhraseApp+CLI+migration).