### Create DMG from App

This lane creates a dmg from a finished build. Therefor it uses the create_dmg.sh script included in this directory. It only works for Mac-Apps and is called after the smf_build_app lane, only when use_sparkle is enabled.