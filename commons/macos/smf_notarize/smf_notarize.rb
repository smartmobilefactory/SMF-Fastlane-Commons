private_lane :smf_notarize do |options|

  should_notarize = options[:should_notarize]

  if should_notarize != true || @platform != :macos
    next
  end

  dmg_path = options[:dmg_path]
  bundle_id = options[:bundle_id]
  username = options[:username]
  asc_provider = options[:asc_provider]
  custom_provider  = options[:custom_provider]


  notarize(
    package: dmg_path,
    bundle_id: bundle_id,
    username: username,
    asc_provider: custom_provider.nil? ? asc_provider : custom_provider,
    print_log: false
  )
end