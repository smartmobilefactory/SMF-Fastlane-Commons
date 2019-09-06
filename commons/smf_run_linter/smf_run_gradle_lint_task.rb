private_lane :smf_run_gradle_lint_task do |options|

  build_variant = !options[:build_variant].nil? ? options[:build_variant] : ''
  modules = smf_danger_module_config(options)

  modules.each do |item|
    module_name = item['module_name'] != '' ? "#{item['module_name']}:" : ''
    gradle(task: "#{module_name}lint" + build_variant)
  end
end
