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
    'version' => report['targetSdkVersion'].to_s
  })

  dependencies.append({
    'name' => 'androidMinSdk',
    'version' => report['minSdkVersion'].to_s
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
    'version' => report['compileSdkVersion'].to_s
  })

  dependencies.append({
    'name' => 'kotlin',
    'version' => report['kotlinVersion'].to_s
  })

  dependencies.append({
    'name' => 'androidGradlePlugin',
    'version' => report['gradleVersion'].to_s
  })

  dependencies.append({
    'name' => 'androidBuildTools',
    'version' => report['buildToolsVersion'].to_s
  })

  apiData = {
    'software_versions' => dependencies,
    'type' => 'development',
    'package_manager' => 'gradle',
    'project_type' => 'Android'
  }
  apiData
end

#
# scanns project dependencies for security issues
# example output
# [
#   {
#     "id": "com.google.guava:guava",
#     "version": "21.0",
#     "vulnerabilities": [
#       "CVE-2018-10237"
#     ]
#   }
# ]
#
def smf_owasp_report_android
  gradle(task: 'dependencyCheckAnalyze')
  report = []
  owasp_report = JSON.parse(File.read(smf_get_file_path('dependency-check-report.json')), :symbolize_names => false)
  owasp_report['dependencies'].each { |dependency|
      vulnerabilities = dependency['vulnerabilities']
      if !vulnerabilities.nil? && !vulnerabilities.empty?
          vulnerabilityNames = vulnerabilities.map { |it| it['name'] }
          dependency['packages'].each { |package|
              # example: pkg:maven/com.squareup.okhttp3/okhttp@3.10.0",
              packageIdMatch = package['id'].match(/pkg:maven\/(.*)@(.*)/)
              if packageIdMatch
                  report.append({
                      'id' => packageIdMatch[1].gsub('/', ':'),
                      'version' => packageIdMatch[2],
                      'vulnerabilities' => vulnerabilityNames
                  })
              end
          }
      end
  }
  report
end
