## Get filepaths to attach to Github Release
This lane is used for macOS app builds and returns the file paths (to the .app and Unittest results) which should be attached to the github release.
A dictionary with project names as keys and the name for the app which will be attached has to be passed which contains the projects for which the files should be attached.
Example:
```
paths = smf_get_file_to_attach_to_release(
        build_variant: "alpha",                     # The proejcts current build variant
        projects: { "HiDrive" => "HiDrive"},        # Dictionary containing the projects for which the files should be attached
        project_name: "HiDrive-macOS"               # The projects name
    )
```
