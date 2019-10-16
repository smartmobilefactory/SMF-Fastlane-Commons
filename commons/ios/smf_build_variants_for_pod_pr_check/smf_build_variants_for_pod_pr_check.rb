private_lane :smf_build_variants_for_pod_pr_check do

  all_build_variants = @smf_fastlane_config[:build_variants].keys.map(&:to_s)

  # Check for alpha in build variants.
  alpha_build_variant = all_build_variants.detect { |variant| variant.match(/.*alpha.*/) }

  # If there is an alpha return this alpha in an array. Otherwise return all build variants which contain 'example'.
  if alpha_build_variant.nil?
    example_build_variants = []
    all_build_variants.map do |variant|
      example_build_variants.push(variant) if variant.match(/.*example.*/)
    end
    matching_build_variants = example_build_variants
  else
    matching_build_variants = [alpha_build_variant]
  end

  UI.important("Found matching build variants: #{matching_build_variants} for pod PR check.")

  matching_build_variants
end