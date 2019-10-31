
private_lane :smf_read_changelog do |options|
  changelog = nil
  if options[:html] == true
    UI.message("Reading changelog from #{_smf_changelog_html_temp_path}")
    changelog = File.read(_smf_changelog_html_temp_path).to_s
  else
    UI.message("Reading changelog from #{_smf_changelog_temp_path}")
    changelog =  File.read(_smf_changelog_temp_path).to_s
  end

  # return the changelog as string
  changelog
end
