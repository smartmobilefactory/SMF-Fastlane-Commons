private_lane :smf_build_variants_for_pod_pr_check do |options|

  #####
  #TODO: Check if this works without any given paramters (pipeline: PR check)
  #####

  matching_build_variants = []
  all_build_variants = @smf_fastlane_config[:build_variants].keys.map(&:to_s)

  # Check for alpha in build variants of hte Config.json and returns the first one found.
  alpha_build_variant = all_build_variants.detect { |variant| variant.match(/.*alpha.*/) }

  # If a specific build_variant has been specified in the pipeline use it instead of the other ones.
  if !options[:build_variant].nil?
    matching_build_variants = [options[:build_variant]] # make an array out of it
  # If there is no alpha return all build variants which contain 'example' or 'unittests'.
  if alpha_build_variant.nil?
    matching_build_variants = _smf_build_variants_matching(/.*example.*/, all_build_variants)

    if matching_build_variants.empty?
      matching_build_variants = _smf_build_variants_matching(/.*unittests.*/, all_build_variants)
    end
  # If there is an alpha, use it as default build_variant
  else
    matching_build_variants = [alpha_build_variant]
  end

  if matching_build_variants.empty?
    UI.error("Error, couldn't find any build variants containing 'alpha', 'example' or 'unittests' in their name.")
    raise "Error finding matching build variants"
  else
    UI.important("Found matching build variants: #{matching_build_variants}.")
  end

  matching_build_variants
end

def _smf_build_variants_matching(regex, all_build_variants)
  matching_build_variants = []
  all_build_variants.map do |variant|
    matching_build_variants.push(variant) if variant.match(regex)
  end

  matching_build_variants
end