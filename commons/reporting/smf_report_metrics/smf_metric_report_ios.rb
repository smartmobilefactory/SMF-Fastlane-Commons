def smf_dependency_report_cocoapods

  podfile = YAML.load(File.read(smf_get_file_path('Podfile.lock')))

  dependencies = []
  podfile['DEPENDENCIES'].each { |value|

    if match = value.match(/([-\/0-9A-Z_a-z]*)(?:[^\d\n]*([\d\.]*)[^\d\n]*)?/)
      name, version = match.captures

      if version == ""
        version = "0.0.0"
      end

      dependencies.push({
                            'name' => name,
                            'version' => version
                        })
    end
  }

  dependencies = smf_dependency_report_fetch_cocoapods_licences(dependencies)
  apiData = {
      'software_versions' => dependencies,
      'type' => 'dependency',
      'package_manager' => 'cocoapods'
  }
  apiData
end

def smf_dependency_report_fetch_cocoapods_licences(dependencies)
  dependencies.each { |value|
    name = value['name'].split('/')[0]
    begin
      uri = URI.parse("https://metrics.cocoapods.org/api/v1/pods/#{name}")
      request = Net::HTTP::Get.new(uri.request_uri)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      response = http.request(request)
      if response.code == '200'
        data = JSON.parse(response.body)
        value['license'] = data['cocoadocs']['license_short_name']
      else
        UI.message("Failed to query pod details for #{name}, #{response.code}: #{response.message}")
      end
    rescue Exception => ex
      UI.message("Failed to query pod details for #{name}, #{ex.message}")
    end
  }

  dependencies
end

