private_lane :smf_read_changelog do |options|
  UI.message("Reading changelog from #{_smf_changelog_temp_path}")

  File.read(_smf_changelog_temp_path).to_s
end