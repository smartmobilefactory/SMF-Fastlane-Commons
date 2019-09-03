### Synchorize String with Phraseapp
This lane is used to synchronize string with phrase app. 
Androids has a separate fastlane action which can be used by overwriting the setup_dependencies lane in the projects fastfile.

Example:

```
smf_sync_with_phrase_app(<map_with_necessary_phraseapp_properties>)
```

#### Phrase App Synchronisation Variables
The Phrase-App synchronisation scripts need certain environment variables. The values for theses variables are stored in the nested dictionary `phrase_app`. 
These entries exist for each build variant that needs to sync with phrase app and are therefore nested inside the given build-variant entry.

##### Disabling PhraseApp Entry Temporarily
If a set of phrase app variables has to be disabled, the convention is to rename the `phrase_app` entry to `phrase_app_DISABLED`. 
This way the phrase app sync scripts will ignore the entry, but the variables and values can be kept in the config.json to be enabled and used at a later time.

##### Keys & Values
| Key | Default Value | Datatype | Mandatory | Description |
|-----|---------------|----------|-----------|--------------
| `access_token_key` | "SMF_PHRASEAPP_ACCESS_TOKEN" | String | ✅ |	The variable name in which jenkins stores the access token for the phrase app api. The default value is "SMF_PHRASEAPP_ACCESS_TOKEN" which should work for almost all projects. An exception are the Strato projects, they should use "stratoPhraseappAccessToken". |
| `project_id` | nil | String | ✅ |The projects phrase app id which is used in the api call to identify the correct project. This should be an all lowercase hexadecimal string with 32 digits. For example "12abc345bf6e980d96e5b0a236fe78b1"|
| `source` | nil | String | ✅ | This value should be an identifier for the language which is used as source for the translation. This is "en" in the most of the cases. |
| `locales` | nil | Array of Strings | ✅ | A list of language identifiers to which the strings of the app will be translated. For example `["de", "at", "es", "fr"]`. |
| `format` | nil | String | ✅ | Determines the format in which the phrase app translation files are stored. This is in almost all cases "strings". But it could also be for example "simple_json" or "xml" or another format. |
| `base_directory` | nil | String | ✅ | This string specifies the base directory in which the different translation files will be stored. |
| `files` | nil | Array of Strings | ✅ | A list of files which will be translated. |
| `git_branch` | @smf_git_branch | String | | The projects git branch to which new or changed translations will be pushed. The default is the branch which is passed to the fastlane build job. |
| `files_prefix` | "" | String | | Specifies a prefix for the file tags. |
| `forbid_comments_in_source` | true | Bool | | If this is set to true, the phrase app scripts abort if the find an comments in the source file. This is due to some weird behavoir of the PhrasApp if there are comments in the source file. |

If there are extensions which need to be synced with the phrase app, too, this can be done by adding an "extensions" array nested in the "phrase_app" entry. For each extension the array should contain entries with keys: "project_id", "base_directory" and "files".
Here is a template for the "phrase_app" structure:

```
	"phrase_app" : {
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
}

```
