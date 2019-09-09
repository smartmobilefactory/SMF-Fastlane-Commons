private_lane :smf_run_detekt do |options|

  modules = smf_danger_module_config(options)

  modules.each do |item|
    module_name = item['module_name'] != '' ? "#{item['module_name']}:" : ''
    next if item['run_detekt'] == false

    gradle(task: "#{module_name}detekt")
  end
end
