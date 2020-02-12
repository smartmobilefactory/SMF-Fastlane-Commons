def meta_db_project_name
  name = @smf_fastlane_config[:project][:meta_db_name]
  if name.nil?
    name = @smf_fastlane_config[:project][:project_name]
  end
  name
end
