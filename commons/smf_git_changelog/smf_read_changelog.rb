private_lane :smf_read_changelog do |options|
  UI.message("Reading changelog from #{_smf_changelog_temp_path}")
  changelog = File.read(_smf_changelog_temp_path)

  if options[:remove_changelog] == true
    UI.message("Removing temporary changelog file at #{_smf_changelog_temp_path}")
    sh "rm #{_smf_changelog_temp_path}" if File.exist?(_smf_changelog_temp_path)
  end

  changelog.to_s
end