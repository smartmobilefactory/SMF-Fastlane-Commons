private_lane :smf_run_junit_task do |options|

  junit_task = options[:junit_task]
  modules = smf_danger_module_config(options)

  modules.each do |item|
    module_name = item['module_name'] != '' ? "#{item['module_name']}:" : ''
    gradle(task: "#{module_name}#{junit_task}") if item['junit_task']
  end
end

