private_lane :smf_read_changelog do |options|
  UI.message("REading changelog from #{_smf_changelog_temp_path}")
  changelog = File.read(smf_changelog_temp_path)

  if options[:remove_changelog] == true
    UI.message("Removing temporary changelog file at #{_smf_changelog_temp_path}")
    sh "rm #{smf_changelog_temp_path}" if File.exist?(smf_changelog_temp_path)
  end

  changelog.to_s
end