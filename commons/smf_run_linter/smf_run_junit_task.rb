private_lane :smf_run_junit_task do |options|

  modules = smf_danger_module_config(options)

  modules.each do |item|
    module_name = item['module_name'] != '' ? "#{item['module_name']}:" : ''
    module_junit_task = item['junit_task']
    gradle(task: "#{module_name}#{module_junit_task}") if item['junit_task']
  end
end

