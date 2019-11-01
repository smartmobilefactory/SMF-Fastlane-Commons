# Attaches .app and testfiles to the git tag
# Options:
#.  :projects -> dict with project name and app_name mappings for which the app should be attached to the tag
#
private_lane :smf_get_files_to_attach_to_release do |options|

  build_variant = options[:build_variant]
  projects = options[:projects]
  project_name = options[:project_name]

  # Attach app and test files to release if this is a mac release and the project is in the list for which this should be executed
  if projects.keys.include?(project_name)
    path_to_files_to_attach = []
    path_to_ipa_or_app = smf_path_to_ipa_or_app(build_variant)

    # check if the path is actually pointing to the .app file
    if File.extname(path_to_ipa_or_app) != ".app"
       if File.extname(path_to_ipa_or_app) == ".zip" && File.extname(path_to_ipa_or_app.gsub(".zip", "")) == ".app"
         sh "unzip -o #{path_to_ipa_or_app}"
         path_to_ipa_or_app = path_to_ipa_or_app.gsub(".zip", "")
       else
         UI.message("Couldn't find the .app file to attach it to the github release 😬")
         next
       end
     end

     if projects[project_name] != nil
       path_to_renamed_app_file = File.join(File.dirname(path_to_ipa_or_app), "#{projects[project_name]}.app")
       sh "cp -r #{path_to_ipa_or_app} #{path_to_renamed_app_file}"
       path_to_files_to_attach.push(path_to_renamed_app_file)
     end

     test_dir = "#{smf_workspace_dir}/Tests/SMFTests"
     test_dir_zipped = "#{test_dir}.zip"
     sh "zip -r -q \"#{test_dir_zipped}\" \"#{test_dir}\""
     path_to_files_to_attach.push(test_dir_zipped) # this will be returned
  end
end
