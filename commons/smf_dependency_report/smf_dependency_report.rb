require 'json'

private_lane :smf_dependency_report do |options|
  dependencyReport = nil
  begin
    case @platform
    when :android
      dependencyReport = smf_dependency_report_android(options)
    else
      UI.message("The platform \"#{@platform}\" does not support dependency reports")
    end
  rescue
    UI.message("Platform dependencies could not be reported")
  end

  unless dependencyReport.nil?
    dependencyReport["environment"] = options[:build_variant]
    smf_send_dependency_report(dependencyReport)
  end
end

def smf_dependency_report_android(options)
  gradle(task: 'allLicenseReport')
  dependencies = []
  smf_get_file_paths("license*Report.json").each { |path|
    report = JSON.parse(File.read(path), :symbolize_names => false)
    report.each { |value|
      license = value['licenses'][0]['license'] unless value['licenses'].nil? || value['licenses'].empty?

      dependencies.append({
        'name' => value['dependency'].sub(":#{value['version']}", ""),
        'version' => value['version'],
        'license' => license
      })
    }
  }

  apiData = {
    "software_versions" => dependencies,
    "type" => "dependency",
    "package_manager" => "gradle",
    "environment" => options[:build_variant],
    "project" => "Test",
    "project_type" => "Android"
  }
  apiData
end

def smf_send_dependency_report(report)
  uri = URI('https://metadb.solutions.smfhq.com/api/v1/software')

  https = Net::HTTP.new(uri.host,uri.port)
  https.use_ssl = true

  UI.message("APIKEY: #{ENV["METADB_API_CREDENTIALS"]}")

  req = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
  req.body = report.to_json
  req['Authorization'] = "TODO"

  res = https.request(req)
end