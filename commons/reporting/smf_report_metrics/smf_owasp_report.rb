
def smf_owasp_report_android
  gradle(task: 'dependencyCheckAnalyze')
  _smf_parse_owsap_report
end

def smf_owsap_report_cocoapods
  podfile_path = smf_get_file_path('Podfile.lock')
  sh("dependency-check --enableExperimental --scan #{podfile_path} -f ALL -o ./owasp_report/")
  _smf_parse_owsap_report
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
def _smf_parse_owsap_report
  report = []
  owasp_report = JSON.parse(File.read(smf_get_file_path('dependency-check-report.json')), :symbolize_names => false)
  owasp_report['dependencies'].each { |dependency|
      vulnerabilities = dependency['vulnerabilities']
      if !vulnerabilities.nil? && !vulnerabilities.empty?
          vulnerabilityNames = vulnerabilities.map { |it| it['name'] }
          dependency['packages'].each { |package|
              # example: pkg:maven/com.squareup.okhttp3/okhttp@3.10.0",
              packageIdMatch = package['id'].match(/pkg:maven\/(.*)@(.*)/)

              # example: AFNetworking/Security:3.2.1
              fileNameMatch = dependency['fileName'].match(/(.*):(.*)/)
              if packageIdMatch
                  report.append({
                      'id' => packageIdMatch[1].gsub('/', ':'),
                      'version' => packageIdMatch[2],
                      'vulnerabilities' => vulnerabilityNames
                  })
              elsif fileNameMatch
                  report.append({
                      'id' => fileNameMatch[1],
                      'version' => fileNameMatch[2],
                      'vulnerabilities' => vulnerabilityNames
                  })
              end                
          }
      end
  }
  report
end
