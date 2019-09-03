### Synchorize String with Phraseapp
This lane is used to synchronize string with phrase app. 
Androids has a separate fastlane action which can be used by overwriting the setup_dependencies lane in the projects fastfile.

Example:

```
smf_sync_with_phrase_app(<map_with_necessary_phraseapp_properties>)
```

The phraseapp properties are documented in more detail [here](https://smartmobilefactory.atlassian.net/wiki/spaces/SMFCI/pages/500662273/Config.json+properties).