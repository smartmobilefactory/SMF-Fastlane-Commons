private_lane :smf_run_klint do |options|

  modules = smf_danger_module_config(options)

  modules.each do |item|
    module_name = item['module_name'] != '' ? "#{item['module_name']}:" : ''
    next if item['run_ktlint'] == false
    gradle(task: "#{module_name}ktlint")
  end
end
