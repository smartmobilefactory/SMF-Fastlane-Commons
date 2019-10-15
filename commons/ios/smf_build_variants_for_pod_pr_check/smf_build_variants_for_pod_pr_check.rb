desc "Returns all build variants which contain the word example e.g. they can be build."
private_lane :smf_build_variants_for_pod_pr_check do
  all_build_variants = @smf_fastlane_config[:build_variants].keys.map(&:to_s)
  matching_build_variants = all_build_variants.grep(/.*example.*/)

  UI.important("Found matching build variants: #{matching_build_variants} for pod pr check")

  matching_build_variants
end