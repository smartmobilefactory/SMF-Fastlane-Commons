def smf_dependency_report_android
  gradle(task: 'allLicenseReport')
  dependencies = []
  smf_get_file_paths('license*Report.json').each { |path|
    report = JSON.parse(File.read(path), :symbolize_names => false)
    report.each { |value|
      license = value['licenses'][0]['license'] unless value['licenses'].nil? || value['licenses'].empty?

      dependencies.append({
        'name' => value['dependency'].sub(":#{value['version']}", ''),
        'version' => value['version'],
        'license' => license
      })
    }
  }

  apiData = {
    'software_versions' => dependencies,
    'type' => 'dependency',
    'package_manager' => 'gradle',
    'project_type' => 'Android'
  }
  apiData
end

def smf_general_dependency_report_android
  gradle(task: 'createProjectJson')

  apiData = []
  report = JSON.parse(File.read(smf_get_file_path('.MetaJSON/Project.json')), :symbolize_names => false)
  
  dependencies = []
  dependencies.append({
    'name' => 'androidTargetSdk',
    'version' => report['targetSdkVersion']
  })

  dependencies.append({
    'name' => 'androidMinSdk',
    'version' => report['minSdkVersion']
  })

  apiData = {
    'software_versions' => dependencies,
    'type' => 'general',
    'package_manager' => 'gradle',
    'project_type' => 'Android'
  }
  apiData
end


def smf_development_dependency_report_android
  gradle(task: 'createProjectJson')

  apiData = []
  report = JSON.parse(File.read(smf_get_file_path('.MetaJSON/Project.json')), :symbolize_names => false)

  dependencies = []
  dependencies.append({
    'name' => 'androidCompileSdk',
    'version' => report['compileSdkVersion']
  })

  dependencies.append({
    'name' => 'kotlin',
    'version' => report['kotlinVersion']
  })

  dependencies.append({
    'name' => 'androidGradlePlugin',
    'version' => report['gradleVersion']
  })

  dependencies.append({
    'name' => 'androidBuildTools',
    'version' => report['gradleVersion']
  })

  apiData = {
    'software_versions' => dependencies,
    'type' => 'development',
    'package_manager' => 'gradle',
    'project_type' => 'Android'
  }
  apiData
end
