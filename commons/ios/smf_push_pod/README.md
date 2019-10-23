### Release the Pod
This lane releases a new version of the pod. Because the pod_push lane needs the tag "release/..." to exists (on github), the tag is first pushed to a temporary branch. After that pod_push tries to upload the new pod version. If it fails the temporary branch and the tag is deleted. Otherwise the changes are pushed to the current branch and the temporary branch is deleted.

Example:
```
smf_push_pod(
    podspec_path: <path to the podspec file>,
    specs_repo: <specrepo url>, # optional
    required_xcode_version: <the projects xcode version>
    local_branch: <the projects current local branch>
)
```