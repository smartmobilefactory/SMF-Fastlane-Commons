private_lane :smf_write_changelog do |options|

  sh "rm #{_smf_changelog_temp_path}" if File.exist?(_smf_changelog_temp_path)
  UI.message("Writing changelog temporarily to #{_smf_changelog_temp_path}")
  File.write(_smf_changelog_temp_path, options[:changelog])
end
