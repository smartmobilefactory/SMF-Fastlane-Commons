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