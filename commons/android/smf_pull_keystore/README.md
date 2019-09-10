### Pull Keystore
This lane clones the android keystore repository and decrypts the folder which contains the properties needed to build the app. 
The properties are than combined into a string and will be returned.

Example: 

```
smf_pull_keystore(
   clone_root_folder: <folder_path_in_which_the_repo_will_be_cloned>,   # Defaults to the commons root directory
   folder: <name_of_the_key_store_folder>
)
```