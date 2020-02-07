require 'json'

private_lane :smf_dependency_report do |options|
  build_variant = options[:build_variant]
  dependencyReport = nil
  begin
    case @platform
    when :android
      dependencyReport = smf_dependency_report_android()
    else
      UI.message("The platform \"#{@platform}\" does not support dependency reports")
    end
  rescue
    UI.message("Platform dependencies could not be reported")
  end

  unless dependencyReport.nil?
    dependencyReport["environment"] = build_variant
    dependencyReport["project"] = @smf_fastlane_config["project"]["meta_db_name"]
    smf_send_dependency_report(dependencyReport)
  end
end

def smf_dependency_report_android()
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
  UI.message("data :\n#{report.to_json}")
  auth = ENV["METADB_API_CREDENTIALS"].split(':')
  req.basic_auth auth[0], auth[1]

  res = https.request(req)

  UI.message("dependency data was reported:\n#{res.body}")
end
