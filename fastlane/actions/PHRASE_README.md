# Phrase Synchronisation

## Overview

The fastlane action `sync_with_phrase` can be used to synchronize localizables with phrase.

How this generally works is, we have a default language (android -> default, ios -> base). All localizable/string files from this language are uploaded to phrase (during the upload phase). This way newly added key-values pairs are added to phrase. This does **NOT** override already existings keys-values with new values.

During the download phase, the key-value pairs present in phrase are downloaded into the corresponding files.

## Details

### Android

For Android there are two cases to consider, a **kmpp** project and a normal project.

##### Parameter Overview

| Parameter     | Type          | Optional  | Description |
|:------------- |:------------- |:--------- |:----------- |
|project_id|String|false|The projects id from phrase. Looks like: 123cdef123456abcd32ef34bg234eb|
|resource_dir|String|true|The directory in which the resources of the projects are located (e.g. the values folder). This default to `./app/src/main/res/` for normal android projects and ../core/src/commonMain/resources/MR/` for kmpp projects. Normally this doesn't need to be set.|
|upload_resource\_dir|String|true|For this parameter you can pass in a path to a folder which contains the file you want to upload to phrase. For normal andorid projects this default to `resource_dir` + `values`. For kmpp proejcts this defaults to `resource_dir` + `base`. Set this if your files to upload are located in a different directory.|
|download_resource\_dir|String|true|For this parameter you can pass in a path to a folder in which the subfolders for the different languages are located (or will be created). This defaults to the `resource_dir`.|
|languages|Hash|false|This is a Hash (see Languages Hash Example below this table) which maps the languages to there phrase_ids.|
|is_kmpp|Bool|true|Needs to be set to true if the project is a kmpp project.|
|platform|String|false|TODO|

Languages Hash Example:
```
{
    'default' => 'abcedf123456abcedfe13426ebdac',
    'de' => '125aae89d4a51461c45200ff72baf764',
    ...
}
```

### iOS

| Parameter     | Type          | Optional  | Description |
|:------------- |:------------- |:--------- |:----------- |
|project_id|String|false||
|resource_dir|String|true||
|upload_resource\_dir|String|true||
|download_resource\_dir|String|true||
|languages|Hash|false||
|is_kmpp|Bool|ture||
|platform|String|false||
|use_custom\_api\_token|Bool|true||
|base|String|true||
|extensions|Array|true||