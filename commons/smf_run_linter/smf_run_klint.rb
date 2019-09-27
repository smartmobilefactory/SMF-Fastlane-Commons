private_lane :smf_run_klint do |options|

  project_dir = options[:project_dir]
  gradle_path = options[:gradle_path]
  modules = smf_danger_module_config(options)

  modules.each do |item|
    module_name = item['module_name'] != '' ? "#{item['module_name']}:" : ''
    next if item['run_ktlint'] == false
    gradle(
        task: "#{module_name}ktlint",
        project_dir: project_dir,
        gradle_path: gradle_path
    )
  end
end
