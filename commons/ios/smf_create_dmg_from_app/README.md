### Create DMG from App

This lane creates a dmg from a .app file. Therefor it uses the create_dmg.sh script included in this directory. 
This is used for macOS apps. The lane returns the path to the newly created .dmg.

Example Call:

```
smf_create_dmg_from_app(
    team_id: "JZ2H644EU7",                          # The Team ID to use for the Apple Member Center.
    code_signing_identity: <code signing identity>  # Optional, used for code signing the .dmg if provided
)
```