### Create DMG from App

This lane creates a dmg from a finished build. Therefor it uses the create_dmg.sh script included in this directory. 
It only works for Mac-Apps and is called after the smf_build_app lane, only when use_sparkle is enabled.

Example Call:

```
smf_create_dmg_from_app(
    team_id: "JZ2H644EU7",          # The Team ID to use for the Apple Member Center.
    build_scheme: "HiDrive-Alpha",  # The scheme name as you see it in XCode
)
```