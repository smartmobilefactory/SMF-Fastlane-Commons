private_lane :smf_build_variants_for_pod_pr_check do

  all_build_variants = @smf_fastlane_config[:build_variants].keys.map(&:to_s)

  # Check for alpha in build variants.
  alpha_build_variant = all_build_variants.detect { |variant| variant.match(/.*alpha.*/) }

  # If there is an alpha return this alpha in an array. Otherwise return all build variants which contain 'example'.
  if alpha_build_variant.nil?
    matching_build_variants = _smf_build_variants_matching(/.*example.*/, all_build_variants)

    if matching_build_variants.empty?
      matching_build_variants = _smf_build_variants_matching(/.*unittests.*/, all_build_variants)
    end

    if matching_build_variants.empty?
      UI.error("Error, couldn't find any build variants containing 'example' or 'unittests' in their name.")
      raise "Error finding matching build variants"
    end

  else
    matching_build_variants = [alpha_build_variant]
  end

  matching_build_variants = matching_build_variants.first
  UI.important("Found matching build variants: #{matching_build_variants} for PR check.")

  matching_build_variants
end

def _smf_build_variants_matching(regex, all_build_variants)
  matching_build_variants = []
  all_build_variants.map do |variant|
    matching_build_variants.push(variant) if variant.match(regex)
  end

  matching_build_variants
end