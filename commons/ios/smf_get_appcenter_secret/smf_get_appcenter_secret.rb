require 'json'

private_lane :smf_get_appcenter_secret do |options|

  build_variant = options[:build_variant]
  build_variants = @smf_fastlane_config[:build_variants].keys
  project_dir = smf_workspace_dir

  app_secrets = {}

  build_variants.each { |build_variant|

    app_secrets[build_variant] = []

    build_variant_regex = build_variant.to_s.gsub('_', ')+.*(')
    plist_paths = `find #{project_dir} -type f -name '*.plist'`.split("\n")

    plist_paths.each { |plist_path|

      plist_path = plist_path.gsub(' ', '\ ')

      # ignore pods
      if plist_path.match(/^#{project_dir}\/Pods\/.*$/)
        next
      end

      basename = File.basename(plist_path)

      if basename.downcase().match(/.*(#{build_variant_regex})+.*/)
        plist_content = `cat #{plist_path}`
        matcher = plist_content.match(/<string>appcenter-(.+)<\/string>/)

        if !matcher.nil? and !matcher.captures.nil? and matcher.captures.count == 1
          app_secrets[build_variant].push(matcher.captures[0])
        end
      end
    }

    app_secrets[build_variant].uniq!
  }

  # Remove duplicates from entries by using the ones which only occur once
  app_secrets.keys.each { |key|
    if app_secrets[key].count == 1
      app_secrets.keys.each { |key1|
        if app_secrets[key1].count > 1
          app_secrets[key1].delete(app_secrets[key][0])
        end
      }
    end
  }

  app_secrets[build_variant.to_sym].first
end

# This wrapper is used to track the accuracy of the dynamic appcenter secret extraction.
# If errors occur or wrong values are provided the data is logger to the ci-diagnostic-messages channel
private_lane :smf_get_appcenter_secret_diagnostic_wrapper do |options|

  build_variant = options[:build_variant]

  message_extension = "Project name: #{@smf_fastlane_config[:project][:project_name]}, build variant: #{build_variant}"

  appcenter_secret_dynamically = ''

  begin
    appcenter_secret_dynamically = smf_get_appcenter_secret(
      build_variant: build_variant
    )
  rescue => exception
    smf_send_diagnostic_message(
      title: 'Dynamic appcenter secret extraction',
      message: "Error while dynamically extracting the appcenter secret: #{exception}, #{message_extension}"
    )
    next
  end

  correct_appcenter_secret = @smf_fastlane_config[:build_variants][build_variant.to_sym][:appcenter_id]

  if correct_appcenter_secret != appcenter_secret_dynamically
    smf_send_diagnostic_message(
      title: 'Dynamic appcenter secret extraction',
      message: "Error: the dynamically extracted appcenter secret does not match the one from the Config.json: correct: #{correct_appcenter_secret} vs. dynamic: #{appcenter_secret_dynamically}. #{message_extension}"
    )
  end

  correct_appcenter_secret
end
