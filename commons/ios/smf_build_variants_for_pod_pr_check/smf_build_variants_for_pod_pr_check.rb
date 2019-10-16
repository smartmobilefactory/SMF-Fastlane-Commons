private_lane :smf_build_variants_for_pod_pr_check do

  all_build_variants = @smf_fastlane_config[:build_variants].keys.map(&:to_s)

  # Check for alpha in build variants.
  alpha_build_variant = all_build_variants.detect { |variant| variant.match(/.*alpha.*/) }

  # If there is an alpha return this alpha in an array. Otherwise return all build variants which contain 'example'.
  matching_build_variants = if alpha_build_variant.nil?
                              all_build_variants.map do |variant|
                                return variant if variant.match(/.*example.*/)
                              end
                            else
                              [alpha_build_variant]
                            end

  UI.important("Found matching build variants: #{matching_build_variants} for pod PR check.")

  matching_build_variants
end