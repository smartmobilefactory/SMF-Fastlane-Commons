private_lane :smf_run_klint do |options|

  modules = smf_danger_module_config(options)

  modules.each do |item|
    module_name = item['module_name'] != '' ? "#{item['module_name']}:" : ''
    next if item['run_ktlint'] == false
    gradle(task: "#{module_name}ktlint")
  end
end

def smf_danger_module_config(options)
  module_basepath = !options[:module_basepath].nil? ? options[:module_basepath] : ''
  run_detekt = !options[:run_detekt].nil? ? options[:run_detekt] : true
  run_ktlint = !options[:run_ktlint].nil? ? options[:run_ktlint] : true
  junit_task = options[:junit_task]

  modules = !options[:modules].nil? ? options[:modules] : []

  if modules.empty?
    modules.push(
        {
            'module_name' => module_basepath,
            'run_detekt' => run_detekt,
            'run_ktlint' => run_ktlint,
            'junit_task' => junit_task
        }
    )
  end

  modules
end
