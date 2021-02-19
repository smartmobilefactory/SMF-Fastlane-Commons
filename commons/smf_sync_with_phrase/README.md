# Phrase Synchronisation

## Overview

The fastlane lane `smf_sync_with_phrase` can be used to synchronize localizables with phrase.

How this generally works is, we have a default language (android -> default, ios -> base). All localizable/string files from this language are uploaded to phrase (during the upload phase). This way newly added key-values pairs are added to phrase. This does **NOT** override already existings keys-values with new values.

During the download phase, the key-value pairs present in phrase are downloaded into the corresponding files.

## Details

### Android

For Android there are two cases to consider, a **kmpp** project and a normal project.

##### Parameter Overview

| Parameter     | Type          | Optional  | Description |
|:------------- |:------------- |:--------- |:----------- |
|project_id|String|false|The projects id from phrase. Looks like: 123cdef123456abcd32ef34bg234eb|
|resource_dir|String|true|The directory in which the resources of the projects are located (e.g. the values folder). This defaults to `/app/src/main/res/` for normal android projects and to `/core/src/commonMain/resources/MR/` for kmpp projects. The paths have to be relative to the projects root directory. Normally this doesn't need to be set.|
|upload_resource\_dir|String|true|For this parameter you can pass in a path to a folder which contains the file you want to upload to phrase. For normal andorid projects this defaults to `resource_dir` + `values`. For kmpp proejcts this defaults to `resource_dir` + `base`.  The paths have to be relative to the projects root directory.Set this if your files to upload are located in a different directory.|
|download_resource\_dir|String|true|For this parameter you can pass in a path to a folder in which the subfolders for the different languages are located (or will be created). This defaults to the `resource_dir`. The paths have to be relative to the projects root directory.| 
|languages|Hash|false|This is a Hash (see Languages Hash Example below this table) which maps the languages to their corresponding phrase_ids.|
|is_kmpp|Bool|true|Needs to be set to true if the project is a kmpp project.|

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

| Parameter     | Type          | Optional  | Description |
|:------------- |:------------- |:--------- |:----------- |
|project_id|String|false|The projects id from phrase. Looks like: 123cdef123456abcd32ef34bg234eb|
|resource_dir|String|false| The directory (relative to the projects root directory) which contains the folders wiht the differen locales.|
|upload_resource\_dir|String|true|For this parameter you can pass in a path to a folder which contains the file you want to upload to phrase. For normal ios projects this defaults to `resource_dir` + `base_locale.lproj` where `base_locale` is the value which is passed in the `base` parameter. Set this if your files to upload are located in a different directory.|
|download_resource\_dir|String|true|For this parameter you can pass in a path to a folder in which the subfolders for the different languages are located (or will be created). This defaults to the `resource_dir`. The paths have to be relative to the projects root directory.| 
|languages|Hash|false|This is a Hash (see Languages Hash Example below this table) which maps the languages to their corresponding phrase_ids.|
|use_custom\_api\_token|Bool|true|If there is a custom api token set in the config.json for phraseapp, set this to true to use it.|
|base|String|true|The base locale which is uploaded to phrase. This can either be 'base' or any other commonly known locale (e.g. 'de', 'fr', 'en', ..)|
|extensions|Array|true|An array with a maps of extensions, see 'Extensions' section below for more details.|

#####Languages Hash Example:
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

If an iOS project has extensions which contain Localizable files which should be synced with phrase, too, this can be achieved with the extensions parameter.

######Structure:
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

The `project_id` has to be set to the phrase project id of the extension. The `resource_dir` should be the path from the projects root directory to the folder which contains the locale folders. Finally the `languages` map is structurally the same as the one for the main project, but has to be filled with the extension specific locale ids. As base the same base is used that is given in the `base` parameter for the main projects.

###### Encodings

For iOS, we try to convert the locale file to UTF-8 encoding to prevent wrong interpretation by phrase if the file has a unordinary encoding.  