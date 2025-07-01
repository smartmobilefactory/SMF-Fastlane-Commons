### Create DMG from App

This lane creates a dmg from a .app file. Therefor it uses the create_dmg.sh script included in this directory. 
This is used for macOS apps. The lane returns the path to the newly created .dmg.

Example Call:

```
smf_create_dmg_from_app(
    team_id: "JZ2H644EU7",                          # The Team ID to use for the Apple Member Center.
    code_signing_identity: <code signing identity>  # Optional, used for code signing the .dmg if provided
    dmg_template_path: <Full path to the DMG template> # Optional, if specified, the DMG will be created from a template instead of being created from scratch. This allows customization of the DMG.
)
```

### Informations about DMG templates

- Use the Config.json key `dmg_template_path` -> See Config.json documentation at https://sosimple.atlassian.net/l/c/8fz5gkco
- The template will be copied, and the newly built app will be put in it, keeping the original DMG layout.