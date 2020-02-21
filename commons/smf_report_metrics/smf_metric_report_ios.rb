def smf_dependency_report_cocoapods

  podfile = YAML.load(File.read(smf_get_file_path('Podfile.lock')))

  dependencies = []
  podfile['DEPENDENCIES'].each { |value|

    dependency = value.match(/([0-9a-zA-Z_\/]*) \((.*)\)/)
    version = dependency[2]

    # parse tag from dependency versions like "from `https://github.com/getsentry/sentry-cocoa.git`, tag `3.13.1`"
    tagVersionMatch = version.match(/from \`.*\`, tag \`(.*)\`/)
    if tagVersionMatch
      version = tagVersionMatch[1]
    end

    # converts dependency version from "= 3.13.1" to "3.13.1"
    absoluteVersionMatch = version.match(/[^\d]*(\d.*)/)
    if absoluteVersionMatch
      version = absoluteVersionMatch[1]
    end

    dependencies.append({
        'name' => dependency[1],
        'version' => version
    })
  }

  apiData = {
    'software_versions' => dependencies,
    'type' => 'dependency',
    'package_manager' => 'cocoapods'
  }
  apiData
end
