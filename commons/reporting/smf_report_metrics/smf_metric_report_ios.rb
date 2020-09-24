def smf_dependency_report_cocoapods

  podfile = YAML.load(File.read(smf_get_file_path('Podfile.lock')))

  dependencies = []
  podfile['DEPENDENCIES'].each { |value|

    dependency = value.match(/([0-9a-zA-Z_\/]*) \((.*)\)/)
    UI.message("dependency: #{dependency}")
    version = dependency[2]
    UI.message("version: #{version}")

    # parse tag from dependency versions like "from `https://github.com/getsentry/sentry-cocoa.git`, tag `3.13.1`"
    tagVersionMatch = version.match(/from \`.*\`, tag \`(.*)\`/)
    UI.message("tagVersionMatch: #{tagVersionMatch}")
    if tagVersionMatch
      version = tagVersionMatch[1]
      UI.message("version: #{version}")
    end

    # converts dependency version from "= 3.13.1" to "3.13.1"
    absoluteVersionMatch = version.match(/[^\d]*(\d.*)/)
    UI.message("absoluteVersionMatch: #{absoluteVersionMatch}")
    if absoluteVersionMatch
      version = absoluteVersionMatch[1]
      UI.message("version: #{version}")
    end
    UI.message("dependency[1]: #{dependency[1]}")
    dependencies.push({
        'name' => dependency[1],
        'version' => version
    })
  }

  UI.message("before dependencies")
  dependencies = smf_dependency_report_fetch_cocoapods_licences(dependencies)
  UI.message("dependencies: #{dependencies}")
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
